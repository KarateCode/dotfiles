const WORKMUX = "/Users/michaelschneider/.cargo/bin/workmux";

export default {
  id: 'workmux-status',
  async setup(ctx) {
    // Register with workmux on startup
    try {
      const proc = Bun.spawn([WORKMUX, "register-agent"], {
        stdout: "pipe",
        stderr: "pipe",
      });
      await proc.exited;
    } catch {
      // Ignore registration failures
    }

    const statusBySession = new Map();
    const acceptBusyBySession = new Map();
    const deletedSessions = new Set();
    const childBySession = new Map();
    let reportedStatus;
    let pendingPrompt;
    let statusQueue = Promise.resolve();

    async function writeStatus(status, prompt) {
      try {
        const args = [WORKMUX, "set-window-status", status];
        const proc = Bun.spawn(args, {
          stdout: "pipe",
          stderr: "pipe",
          stdin: prompt !== undefined ? "pipe" : undefined,
        });
        if (prompt !== undefined && proc.stdin) {
          proc.stdin.write(JSON.stringify({ prompt }));
          proc.stdin.end();
        }
        await proc.exited;
      } catch {
        // Ignore status update failures
      }
    }

    function queueStatus(status, prompt) {
      statusQueue = statusQueue.then(
        () => writeStatus(status, prompt),
        () => writeStatus(status, prompt),
      );
      return statusQueue;
    }

    function takePrompt(status) {
      if (status !== 'working') {
        return undefined;
      }
      const prompt = pendingPrompt;
      pendingPrompt = undefined;
      return prompt;
    }

    async function isChildSession(sessionID) {
      const known = childBySession.get(sessionID);
      if (known !== undefined) {
        return known;
      }
      try {
        const session = await ctx.session.get({ sessionID });
        if (!session) {
          return true;
        }
        const isChild = Boolean(session.parentID);
        childBySession.set(sessionID, isChild);
        return isChild;
      } catch {
        return true;
      }
    }

    async function reportAggregateStatus() {
      const statuses = [...statusBySession.values()];
      let status = 'done';

      if (statuses.includes('waiting')) {
        status = 'waiting';
      } else if (statuses.includes('working')) {
        status = 'working';
      }

      if (reportedStatus === status && !(status === 'working' && pendingPrompt !== undefined)) {
        return;
      }

      reportedStatus = status;
      await queueStatus(status, takePrompt(status));
    }

    async function setStatus(sessionID, status) {
      if (!sessionID || deletedSessions.has(sessionID)) {
        return;
      }

      const previous = statusBySession.get(sessionID);
      if (status === 'done' && previous === undefined) {
        return;
      }
      if (status === 'working' && acceptBusyBySession.get(sessionID) === false) {
        return;
      }
      if (previous === status) {
        return;
      }

      statusBySession.set(sessionID, status);
      if (status === 'done') {
        acceptBusyBySession.set(sessionID, false);
      } else {
        acceptBusyBySession.set(sessionID, true);
      }

      await reportAggregateStatus();
    }

    // V2 event subscription
    const controller = new AbortController();
    void (async () => {
      for await (const event of ctx.event.subscribe({ signal: controller.signal })) {
        if (event.type === 'message.updated' && event.properties.info.role === 'user') {
          acceptBusyBySession.set(event.properties.sessionID, true);

          // Capture prompt from user messages
          if (await isChildSession(event.properties.sessionID)) {
            continue;
          }
          const parts = event.properties.info.parts || [];
          const prompt = parts
            .flatMap((part) => (part.type === 'text' && !part.synthetic ? [part.text] : []))
            .join('\n');
          if (prompt.trim()) {
            pendingPrompt = prompt;
            if (reportedStatus === 'working') {
              await queueStatus('working', takePrompt('working'));
            }
          }
        }

        switch (event.type) {
          case 'session.created':
            childBySession.set(event.properties.info.id, Boolean(event.properties.info.parentID));
            break;
          case 'session.status':
            if (event.properties.status.type === 'busy') {
              await setStatus(event.properties.sessionID, 'working');
            }
            if (event.properties.status.type === 'idle') {
              await setStatus(event.properties.sessionID, 'done');
            }
            break;
          case 'permission.asked':
          case 'question.asked':
            await setStatus(event.properties.sessionID, 'waiting');
            break;
          case 'permission.replied':
          case 'question.replied':
            await setStatus(event.properties.sessionID, 'working');
            break;
          case 'session.idle':
            await setStatus(event.properties.sessionID, 'done');
            break;
          case 'session.deleted': {
            const sessionID = event.properties.info.id;
            deletedSessions.add(sessionID);
            acceptBusyBySession.delete(sessionID);
            childBySession.delete(sessionID);
            if (statusBySession.delete(sessionID)) {
              await reportAggregateStatus();
            }
            break;
          }
        }
      }
    })();

    // Return cleanup function
    return () => controller.abort();
  },
};
