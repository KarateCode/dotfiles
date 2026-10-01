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
;; 2. C-z = undo, C-x = cut
;; ===================================================================
;; On the Mac, Ghostty turns cmd+z / cmd+x into private escape sequences
;; that init.el binds to undo and cut.  Linux has no cmd modifier (and
;; keyd puts Ctrl where cmd lives on the Mac), so the muscle memory lands
;; on C-z and C-x.
;;
;; C-x CANNOT simply be rebound -- it is *the* Emacs prefix key, and
;; init.el leans on C-x C-s, C-x k, C-x f, C-x C-c.  `cua-mode' is the
;; supported way to get "C-x cuts when a region is active, stays a prefix
;; otherwise", and it hands over C-z = undo at the same time.

(require 'cua-base)

(setq cua-enable-cua-keys t          ; C-x cut / C-z undo without needing S-<move>
      cua-remap-control-z t          ; C-z -> undo
      cua-remap-control-v nil        ; leave C-v / M-v alone: init.el binds them
                                     ; to my/scroll-half-page-{down,up}
      cua-keep-region-after-copy nil
      cua-prefix-override-inhibit-delay 0.2
      cua-delete-selection t)        ; typing with a region active replaces it

(cua-mode 1)

;; -------------------------------------------------------------------
;; KNOW THIS ABOUT C-x: the 0.2s ambiguity
;; -------------------------------------------------------------------
;; With a region ACTIVE, pressing C-x starts a 0.2s timer:
;;   * another key within 0.2s  -> C-x acted as a prefix (C-x C-s saves)
;;   * timer expires            -> C-x CUT the region, and your next key
;;                                 runs standalone (so C-s = isearch, not save)
;; With no region active, C-x is an ordinary prefix and none of this applies.
;;
;; Escape hatch that WORKS IN A TERMINAL:  C-x C-x <key>
;;   Double-tapping the prefix hits `cua--prefix-repeat-handler', which
;;   cancels the timer and arms C-x as a plain prefix with no time limit.
;;   To save deliberately while a region is live:  C-x C-x C-s
;;
;; Escape hatch that does NOT work in a terminal:  S-C-x
;;   cua binds S-C-x to `cua--shift-control-x-prefix', but a terminal
;;   cannot encode shift on a control character (C-x is the byte 0x18;
;;   there is no bit left for shift).  GUI frames only.
;;
;; If 0.2s is too tight, raise `cua-prefix-override-inhibit-delay' above.
;; If it is not worth the trouble at all, delete this whole section and
;; use the one-liner  (global-set-key (kbd "C-z") #'undo)  -- that is all
;; the C-z problem actually needs.  Cut already exists on C-w
;; (`smart-kill-region-or-word' in init.el).

;; Untouched by cua-mode, confirmed: C-y stays `my/yank-as-single-undo',
;; C-w stays `smart-kill-region-or-word', C-d stays `my/delete-or-region',
;; C-t stays `projectile-find-file' -- all as bound in init.el.
;; C-<return> becomes cua-rectangle-mark-mode, which init.el leaves unbound.

;; Keep C-c a PURE prefix.  init.el hangs a lot off it (C-c p, C-c l l,
;; C-c l a, C-c y, C-c -), and cua would otherwise make every one of those
;; timing-sensitive whenever a region happened to be active.  Set
;; `omarchy/cua-keep-control-c-as-prefix' to nil if you decide you want
;; C-c to copy after all.
(defvar omarchy/cua-keep-control-c-as-prefix t
  "When non-nil, prevent `cua-mode' from stealing C-c for copy.")

(when omarchy/cua-keep-control-c-as-prefix
  ;; Runs after `cua-mode', which populates these in cua--init-keymaps.
  ;; boundp-guarded so an Emacs upgrade that renames these internals
  ;; degrades to "C-c also copies" rather than breaking startup.
  (when (boundp 'cua--cua-keys-keymap)
    (define-key cua--cua-keys-keymap [(control c) timeout] nil))
  (when (boundp 'cua--prefix-override-keymap)
    (define-key cua--prefix-override-keymap [(control c)] nil))
  (when (boundp 'cua--prefix-repeat-keymap)
    (define-key cua--prefix-repeat-keymap [(control c) (control c)] nil)
    (dolist (key '(up down left right next prior home end))
      (define-key cua--prefix-repeat-keymap (vector '(control c) key) nil)))
  (when (boundp 'cua--region-keymap)
    (define-key cua--region-keymap [(shift control c)] nil)))

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

(provide 'init_omarchy)
;;; init_omarchy.el ends here
