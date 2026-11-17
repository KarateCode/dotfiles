;;; init_omarchy.el --- Linux/Omarchy Emacs overrides -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Machine-specific overrides for the Omarchy (Linux) box.  init.el is
;; shared with the Mac and must stay untouched; this file is loaded
;; AFTER it and wins on anything it redefines.
;;
;; House rule for this file: anything it overrides is copied here in
;; FULL.  No half-definitions, no variables declared in init.el and set
;; here.  If you want to know what a key does on Omarchy, grep this file
;; first -- whatever you find is the whole story.  The cost is that a
;; function edited in init.el must be re-copied here.  Cross-references
;; below name the init.el symbol rather than a line number, on purpose:
;; line numbers went stale the first time init.el grew a header.
;;
;; -------------------------------------------------------------------
;; Why C-z exists in two completely different forms
;;
;; 1. INSIDE EMACS, C-z is bound by default to `suspend-frame', which on
;;    a terminal frame raises SIGTSTP.  Emacs runs the tty in raw mode
;;    (ISIG off), so the kernel never sees a susp character -- this is
;;    purely an Emacs keybinding.  Ghostty passes the 0x1a byte through
;;    untouched, and Bash is only the messenger printing "[3]+ Stopped".
;;    => Handled in section 1 below.
;;
;; 2. OUTSIDE EMACS (bare prompt, bat, less, man, psql...) C-z is the tty
;;    line discipline's `susp' control character, handled by the kernel,
;;    not by any program.  No Emacs setting can touch it.
;;    => Handled in dotfiles/alias.sh with `stty susp undef' (commit
;;       4a6c998).  Not bash/init_omarchy.bash: that is one-time setup, and
;;       tty settings reset on every new pty, so it must run per-shell.
;;       Verify with:  stty -a | tr ';' '\n' | grep susp

;;; Code:

;; ===================================================================
;; 1. Stop Emacs from suspending itself
;; ===================================================================

(global-unset-key (kbd "C-z"))     ; section 2 re-binds this to `undo'
(global-unset-key (kbd "C-x C-z"))

(defun omarchy/no-suspend (&rest _)
  "Refuse to suspend Emacs.  Overrides `suspend-frame' on Linux."
  (interactive)
  (message "Suspend disabled (see init_omarchy.el)"))

;; Belt and braces: even if something else reaches `suspend-frame'
;; (M-x, a mode-local binding, a stray escape sequence), don't background.
(advice-add 'suspend-frame :override #'omarchy/no-suspend)

;; ===================================================================
;; 2. C-z = undo.  (cua-mode RETIRED -- see below)
;; ===================================================================
;; HISTORY, because deleting a whole subsystem deserves a note:
;;
;; This section used to enable `cua-mode'.  The reasoning was that on the
;; Mac, Ghostty turns cmd+z / cmd+x into private escape sequences bound to
;; undo and cut, while "Linux has no cmd modifier (and keyd puts Ctrl where
;; cmd lives on the Mac), so the muscle memory lands on C-z and C-x".  cua
;; was the supported way to get "C-x cuts when a region is active, stays a
;; prefix otherwise", and it supplied C-z = undo in the same breath.
;;
;; THAT PREMISE IS GONE.  keyd now rewrites the Cmd-position chords to
;; ctrl+alt+<key> carriers (see ~/dotfiles/keyd/app.conf), Ghostty turns
;; those into the same private sequences the Mac uses, tmux passes them
;; through as user-keys, and init.el decodes them:
;;
;;   Cmd+X       -> \x1b[120;9z -> [cmd-x]       -> custom-cut-line-or-region
;;   Cmd+Z       -> \x1b[108;9z -> [cmd-z]       -> undo
;;   Cmd+Shift+Z -> \x1b[109;9z -> [cmd-shift-z] -> undo-redo
;;
;; So cua had nothing left to do, and it was charging rent: with a region
;; ACTIVE it made C-x ambiguous for 0.2s (cut vs. prefix), which meant
;; C-x C-s could silently cut instead of save if you typed it slowly.  It
;; also needed ~20 lines of keymap surgery to stop it eating C-c, since
;; init.el hangs C-c p, C-c l l, C-c l a, C-c y and C-c - off that prefix.
;;
;; Retiring it restores C-x and C-c to PURE Emacs prefixes, no timers.
;;
;; All that is left is the one-liner the old section recommended as its own
;; fallback: "that is all the C-z problem actually needs."  Section 1 above
;; unsets C-z to stop `suspend-frame'; this puts undo there instead, which
;; is exactly what cua-remap-control-z used to provide.
;;
;; Cut still exists on C-w (`smart-kill-region-or-word' in init.el), and
;; copy on M-w -- section 4 routes every kill to the Wayland clipboard via
;; `interprogram-cut-function', so neither needs a cmd key.

(global-set-key (kbd "C-z") #'undo)

;; ===================================================================
;; 3. Clipboard paste -- pbpaste does not exist on Linux
;; ===================================================================
;; init.el defines `my/clipboard-paste-as-single-undo', which shells out
;; to the macOS-only `pbpaste', and binds it to <f4>.  On Omarchy that
;; command is missing, so <f4> pasted nothing at all.
;;
;; Below is a COMPLETE replacement, not a patch: the body is copied
;; verbatim from that function and only the clipboard read is swapped for
;; Wayland's wl-paste.  If you ever change the original, re-copy it.

(defun omarchy/clipboard-text ()
  "Return the Wayland system clipboard as a string, or \"\" if unavailable.

Uses `call-process' rather than `shell-command-to-string' on purpose:
the latter routes stderr into its return value, so an empty clipboard
would paste wl-paste's \"Nothing is copied\" complaint into the buffer.
A destination of (t nil) sends stdout here and discards stderr."
  (with-temp-buffer
    (if (and (executable-find "wl-paste")
             (zerop (call-process "wl-paste" nil '(t nil) nil "--no-newline")))
        (buffer-string)
      "")))

(defun omarchy/clipboard-paste-as-single-undo ()
  "Paste the system clipboard with proper indentation, grouped as single undo.
In org-mode, skip auto-indentation to preserve original whitespace.

Linux counterpart of `my/clipboard-paste-as-single-undo' in init.el."
  (interactive)
  (let ((handle (prepare-change-group))
        (text (string-trim-right (omarchy/clipboard-text) "[\n\r]+")))
    (unwind-protect
        (progn
          (activate-change-group handle)
          (when (use-region-p)
            (delete-region (region-beginning) (region-end)))
          (let ((start (point)))
            (insert text)
            ;; Only indent in non-org modes
            (unless (derived-mode-p 'org-mode)
              (indent-region start (point)))))
      (accept-change-group handle)
      (undo-amalgamate-change-group handle))))

;; Repoint init.el's <f4> binding at the Linux version.
(global-set-key (kbd "<f4>") #'omarchy/clipboard-paste-as-single-undo)

;; Note: plain ctrl+shift+v already pastes without any of the above,
;; because Ghostty binds it to paste_from_clipboard by default on Linux
;; and never forwards it to Emacs.  (A terminal cannot express C-S-v
;; anyway -- no room for a shift bit on a control byte -- which is why the
;; macOS side of init.el resorts to escape sequences like \e[108;9z.)

;; ===================================================================
;; 4. Clipboard copy -- the other half of section 3
;; ===================================================================
;; M-w is stock `kill-ring-save' -> `kill-new' -> `interprogram-cut-function'
;; -> `gui-select-text', and that last step is a silent no-op on a TTY frame,
;; which is every frame here (`van' runs `emacsclient -nw').  The Mac copies
;; via [cmd-c] -> pbcopy, a binding that needs a cmd key, so Linux had nothing.
;; Replacing the hook rather than binding a command covers M-w, C-w, C-k and
;; cua's C-x cut all at once.
;;
;; Needs WAYLAND_DISPLAY in the daemon; emacs.service lacked it until
;; ~/.config/systemd/user/emacs.service.d/wayland-env.conf reordered it.

(defvar omarchy/wl-copy-log
  (expand-file-name (format "emacs-wl-copy-%s.log" (user-real-login-name))
                   temporary-file-directory)
  "Scratch file collecting wl-copy's output.  Read only when it fails.")

(defun omarchy/clipboard-set-text (text &rest _)
  "Put TEXT on the Wayland clipboard with wl-copy.
Installed as `interprogram-cut-function', so it runs on every kill."
  (when (and (stringp text) (not (string-empty-p text)))
    (if (not (executable-find "wl-copy"))
        (message "wl-copy not found: kill-ring only, nothing sent to the clipboard")
      ;; Output MUST go to a file, not a buffer: wl-copy forks a server that
      ;; inherits stdout, so a buffer destination makes Emacs read a pipe that
      ;; never reaches EOF and the whole daemon freezes.
      (let* ((coding-system-for-write 'utf-8)
             (status (call-process-region
                      text nil "wl-copy" nil
                      (list (list :file omarchy/wl-copy-log) t) nil)))
        (unless (eq status 0)
          (message "wl-copy failed (exit %s): %s" status
                   (string-trim
                    (with-temp-buffer
                      (ignore-errors (insert-file-contents omarchy/wl-copy-log))
                      (buffer-string)))))))))

(setq interprogram-cut-function #'omarchy/clipboard-set-text)

(with-eval-after-load 'move-text
  (global-set-key (kbd "C-M-<up>")   #'move-text-up)
  (global-set-key (kbd "C-M-<down>") #'move-text-down))

;; ===================================================================
;; 5. Cmd+X cut -- pbcopy does not exist on Linux
;; ===================================================================
;; init.el's `custom-cut-line-or-region' shells out to the macOS-only
;; `pbcopy'.  Once keyd/Ghostty/tmux started delivering [cmd-x] on this
;; box (app.conf `cmd.x = C-A-x' -> \x1b[120;9z), the key finally reached
;; the function and it died on the spot with
;;     Searching for program: no such file or directory, pbcopy
;;
;; House rule applies: the body is copied from init.el in full, and only
;; the clipboard write is swapped -- for `omarchy/clipboard-set-text'
;; (section 4), which drives wl-copy and already works around wl-copy's
;; forked-server stdout trap.  Re-copy this if the original changes.
;;
;; ONE DELIBERATE DEVIATION from init.el: the "Cut: region/line" message
;; is computed BEFORE `delete-region'.  In the original it runs after, by
;; which point the region no longer exists, so `use-region-p' is always
;; nil and it reported "line" even when cutting a region.

(defun custom-cut-line-or-region ()
  "Cut region or current line to the system clipboard (not kill-ring).
Linux counterpart of the `custom-cut-line-or-region' in init.el."
  (interactive)
  (let* ((regionp (use-region-p))
         (start (if regionp (region-beginning) (line-beginning-position)))
         (end   (if regionp (region-end) (line-beginning-position 2)))
         (text  (buffer-substring-no-properties start end)))
    (omarchy/clipboard-set-text text)
    ;; Delete the text without touching kill-ring
    (delete-region start end)
    (message "Cut: %s" (if regionp "region" "line"))))

;; ===================================================================
;; 6. Stray "u" when typing shift+space after popping out of Claude
;; ===================================================================
;; SYMPTOM: open Emacs from inside Claude Code (C-g -> $EDITOR ->
;; emacs-editor.sh -> emacsclient -nw) and shift+space inserts the
;; letter "u" instead of a space.  Everywhere else shift+space is a
;; perfectly ordinary space.
;;
;; THE CHAIN, each link verified rather than assumed:
;;
;; 1. Claude turns on enhanced keyboard reporting.  Captured straight off
;;    its pane with `tmux pipe-pane':
;;        ESC [ > 5 u      push kitty keyboard flags (1|4)
;;        ESC [ > 4 ; 2 m  modifyOtherKeys level 2
;;    It pops these on exit, but NOT before handing the terminal to
;;    $EDITOR -- so Emacs inherits a terminal in enhanced mode.
;;
;; 2. In that mode the terminal stops folding shift+space into a plain
;;    0x20 and reports it as a distinct modified key.
;;
;; 3. tmux re-encodes it for the pane.  `extended-keys' is on and
;;    `extended-keys-format' is csi-u, so Emacs receives
;;        ESC [ 3 2 ; 2 u          (32 = space, 2 = shift)
;;
;; 4. Emacs has NO support for the kitty/CSI-u key encoding -- the only
;;    occurrence of "kitty" anywhere in Emacs 31's lisp is an OSC52
;;    clipboard regexp in term/xterm.el.  So it eats "ESC [ 3 2 ; 2",
;;    fails to recognise the final "u", and self-inserts it.
;;
;; WHY THE FIX IS HERE AND NOT IN emacs-editor.sh:
;; Resetting the modes in the wrapper before exec'ing emacsclient does
;; not survive -- Emacs re-requests modifyOtherKeys itself during
;; terminal setup, after the wrapper has run.  Tested; still produced
;; the stray "u".  Teaching Emacs to decode the sequence is the only
;; layer that actually holds.
;;
;; Switching tmux to `extended-keys-format xterm' does not help either:
;; Emacs then inserts "2~" instead of "u".  Also tested.
;;
;; C-SPC MATTERED MORE THAN SHIFT+SPACE: the same encoding covers
;; ctrl+space, so `set-mark-command' was silently typing a "u" too.
;; Both are handled below.
;;
;; Modifier numbering is 1 + (shift 1 | alt 2 | ctrl 4).
;; If OTHER keys start emitting stray characters in this situation, the
;; general answer is the `kkp' package (full kitty-protocol support)
;; rather than extending this table indefinitely.

;; `input-decode-map' is TERMINAL-LOCAL, which matters here because this
;; is a daemon: defining the entries once at load time binds them to
;; whatever terminal happens to be current, and every `emacsclient -nw'
;; frame afterwards gets a fresh one without them.  Verified the hard
;; way -- a one-shot `dolist' here fixed the daemon but new frames still
;; typed "u".  Hence `tty-setup-hook', which runs once per new tty.

(defun omarchy/decode-csi-u-space ()
  "Teach this terminal the CSI-u encodings of space with modifiers.
See the commentary above section 6 for why Emacs needs this at all."
  (dolist (pair '((2 . [?\s])         ; shift+space        -> space
                  (3 . [?\M-\s])      ; alt+space          -> M-SPC
                  (4 . [?\M-\s])      ; shift+alt+space    -> M-SPC
                  (5 . [?\C-@])       ; ctrl+space         -> set-mark
                  (6 . [?\C-@])       ; ctrl+shift+space   -> set-mark
                  (7 . [?\C-\M-@])    ; ctrl+alt+space     -> C-M-SPC
                  (8 . [?\C-\M-@])))  ; ctrl+alt+shift+spc -> C-M-SPC
    (define-key input-decode-map
                (format "\e[32;%du" (car pair)) (cdr pair))))

(add-hook 'tty-setup-hook #'omarchy/decode-csi-u-space)

;; Cover the terminal this file is being loaded from, if it is one --
;; `tty-setup-hook' has already fired for it by now.
(when (eq (framep (selected-frame)) t)
  (omarchy/decode-csi-u-space))

;; -------------------------------------------------------------------
;; 7. Pin the background mode
;; -------------------------------------------------------------------
;; On a TTY frame Emacs guesses light/dark from $TERM, and xterm-ghostty
;; matches its hardcoded `^xterm' light rule -- which resolves a dark theme's
;; faces down their light branch.  Setting this short-circuits the guess.
(setq frame-background-mode 'dark)

(dolist (frame (frame-list))
  (frame-set-background-mode frame))

(provide 'init_omarchy)
;;; init_omarchy.el ends here
