(require 'package)
(add-to-list 'package-archives '("gnu" . "elpa.gnu.org") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(unless (package-installed-p 'org)
  (package-refresh-contents)
  (package-install 'org))

;; Sane Defaults
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
;; Force the "TS" modes to 4 globally as a backup
(setq-default typescript-ts-indent-offset 4)
(setq-default typescript-ts-mode-indent-offset 4)
(setq-default js-indent-level 4)
(setq-default css-indent-offset 4)


(use-package vertico
  :ensure t
  :init
  (vertico-mode))
(use-package consult
  :ensure t
  :bind (("C-x b" . consult-buffer))) ;; Replaces the simple prompt with a searchable list
(use-package marginalia
  :ensure t
  :init
  (marginalia-mode)) ;; Adds info like buffer size/mode to the popup list
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion))))
  (orderless-matching-styles '(orderless-literal orderless-regexp orderless-flex))
)
(use-package multiple-cursors
  :ensure t
  :bind (("C-S-<up>" . mc/mark-previous-like-this)
         ("C-S-<down>" . mc/mark-next-like-this)))
(use-package projectile
  :ensure t
  :init
  ;; Detect projects automatically using VCS (git, etc.)
  (projectile-mode +1)
  :config
  ;; Use 'find' or 'git ls-files' for performance on large projects
  (setq projectile-indexing-method 'alien)
  (setq projectile-use-git-grep t)

  ;; Setup the standard keymap
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))
(use-package dirvish
  :ensure t
  :init
  (dirvish-override-dired-mode)
  :config
  ;; 1. Unbind the default fill-column command
  (global-unset-key (kbd "C-x f"))
  ;; 2. Bind dirvish-side to C-x f
  (global-set-key (kbd "C-x f") #'dirvish-side)
  :bind
  (:map dired-mode-map
      ("TAB" . dirvish-subtree-toggle)))
(use-package treesit-auto
  :ensure t
  :custom
  (treesit-auto-install 'prompt)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode))

(use-package yasnippet
  :ensure t
  :init
  (yas-global-mode 1)
  :config
  ;; Optional: Add a personal snippets directory for your own creations
  (add-to-list 'yas-snippet-dirs (locate-user-emacs-file "snippets")))
(use-package yasnippet-snippets
  :ensure t
  :after yasnippet)
;; (define-key yas-minor-mode-map (kbd "C-c y") #'yas-expand)

(use-package breadcrumb
  :ensure t
  :init
  (breadcrumb-mode 1)
  :config
  ;; Customizing the look to match Spacemacs
  (setq breadcrumb-project-max-length 0.5) ; Use up to half the window width
  (setq breadcrumb-imenu-max-length 0.3)    ; Use 30% for function/symbol name
  ;; Make it look cleaner (similar to Spacemacs symbols)
  (setq breadcrumb-project-crumb-separator " ▶︎ ")
  (setq breadcrumb-imenu-crumb-separator " ▶︎ ")
)

(use-package doom-themes
  :ensure t
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))
;; Load the specific theme
(load-theme 'doom-horizon t)
;; Enable flashing mode-line on errors
(doom-themes-visual-bell-config)
;; Corrects (and improves) org-mode appearance
(doom-themes-org-config))

(defun my/org-checkbox-pretty-and-colored ()
	"Replace and color Org checkboxes inline."
	(font-lock-add-keywords nil `(
		;; Checked
		("^[ \t]*- \\(\\[X\\]\\)\\(.*\\)" ;; ^\(-\) \(\[X\]\)\(.*\) ;; ^[ \t]*\(- ?\[X\]\) ;; ^- \(\[X\]\)\(.*\)
		(1 (prog1 ()
			(compose-region (match-beginning 0) (match-end 1) ?✔)
		) nil)
		(0 'my/org-checkbox-done-face prepend))

		;; Empty
		("^[ \t]*- \\(\\[ \\]\\)\\(.*\\)" ;; ^[ \t]*- \(\[ \]\)\(.*\)
		(1 (prog1 ()
			(compose-region (match-beginning 0) (match-end 1) ?☐)
		) nil)
		(0 'my/org-checkbox-empty-face prepend))

		;; Partial
		("^[ \t]*- \\(\\[-\\]\\)\\(.*\\)"
		(1 (prog1 ()
			(compose-region (match-beginning 0) (match-end 1) ?✘)
		) nil)
		(0 'my/org-checkbox-partial-face prepend))
	))
)

(defun my/org-checkbox-set-indeterminate ()
  "Set the checkbox at point to indeterminate [-]."
  (interactive)
  (when (org-at-item-checkbox-p)
    (org-toggle-checkbox '(16)))
) ; Prefix arg 16 sets it to [-]

(defface my/org-checkbox-done-face
	'((t :foreground "#8aff8a" :weight normal))
	"Face for checked Org checkbox lines."
)
(defface my/org-checkbox-empty-face
	'((t :foreground "#ffffff" :weight normal))
	"Face for unchecked Org checkbox lines."
)
(defface my/org-checkbox-partial-face
	'((t :foreground "#ff6666" :weight normal))
	"Face for partially checked (indeterminate) Org checkbox lines."
)

(defun delete-current-line (arg)
	"If there's a selection, delete it, otherwise delete current line"

	(interactive "p")
	(when (not (use-region-p))
		(kill-whole-line)
	)
	(when (use-region-p)
		(delete-region (mark) (point))
	)
)

(defun custom-join-lines (arg)
	"My personal better join lines method"
	(interactive "p")
	(end-of-line)
	(delete-char 1)
	(delete-horizontal-space)
)

(defun my/select-current-line-and-forward-line (arg)
	"Select the current line and move the cursor by ARG lines IF
	no region is selected.
	If a region is already selected when calling this command, only move
	the cursor by ARG lines."

	(interactive "p")
	(when (not (use-region-p))
		(forward-line 0)
		(set-mark-command nil)
	)
	(forward-line arg)
)
(defun insert-line-above ()
  "Insert a new line above the current one and move the cursor there.
Preserves column relative to indentation and runs mode indentation."
  (interactive)
  (let ((col (current-column)))
    ;; Go to beginning of current line
    (move-beginning-of-line 1)
    ;; Insert a new line *above*
    (newline)
    ;; Move into the newly created line
    (forward-line -1)
    ;; Indent according to mode
    (indent-according-to-mode)
    ;; Restore column (relative to indentation)
    (move-to-column col))
)

(defun insert-line ()
  "Insert a new line below the current one and move point to it.

	In Org mode:
	- Use `org-return` so new lines inherit checkboxes, indentation, etc.
	- If the new line starts with a checkbox, remove the leading space.

	In all other modes:
	- Use `newline-and-indent` for standard behavior."
	(interactive)
	(end-of-line)
	(if (derived-mode-p 'org-mode)
		;; Org-mode behavior
		(progn
			(org-return)
			(save-excursion
				(beginning-of-line)
				(when (looking-at-p " - \\[[- X]\\]")
					(delete-char 1)
				)
			)
		)
		;; Non-Org-mode fallback
		(newline-and-indent)
	)
)

(defun duplicate-line ()
  "Duplicate the active region or the current line (Sublime-style).
Reselects duplicated region under Spacemacs holy mode."
  (interactive)
  (if (and mark-active transient-mark-mode)
      ;; --- Duplicate region (Sublime style) ---
      (let* ((start (region-beginning))
             (end   (region-end))
             (text  (buffer-substring-no-properties start end))
             (len   (- end start)))
        ;; Insert duplicate
        (goto-char end)
        (insert text)
        ;; Reselect duplicated block reliably
        (setq deactivate-mark nil)
        (push-mark end t t)       ;; sets mark & activates region
        (goto-char (+ end len)))
    ;; --- Duplicate current line ---
    (let ((col (current-column)))
      (save-excursion
        (move-beginning-of-line 1)
        (let ((line (buffer-substring-no-properties
                     (line-beginning-position)
                     (line-end-position))))
          (end-of-line)
          (open-line 1)
          (forward-line 1)
          (insert line)))
      (forward-line 1)
      (move-to-column col)))
)

(defun custom-move-down-7-lines ()
	"Move cursor down exactly 7 lines."
	(interactive)
	(next-line 7)
)

(defun custom-move-up-7-lines ()
	"Move cursor up exactly 7 lines."
	(interactive)
	(previous-line 7)
)

(defun my/comment-or-region ()
	"Comment only the active region if one exists; otherwise comment the current line."
	(interactive)
	(if (use-region-p)
			;; Comment or uncomment the active region only
			(comment-or-uncomment-region (region-beginning) (region-end))
		;; Otherwise, fall back to commenting the current line
		(comment-line 1)
	)
)

(defun my/delete-or-region ()
	"Delete selected region if active; otherwise delete the character at point."
	(interactive)
	(if (use-region-p)
			(delete-region (region-beginning) (region-end))
		(delete-char 1)
	)
)

(defun my/scroll-half-page-down ()
	"Scroll down by half the window height."
	(interactive)
	(scroll-up-command (/ (window-body-height) 2))
)

(defun my/scroll-half-page-up ()
	"Scroll up by half the window height."
	(interactive)
	(scroll-down-command (/ (window-body-height) 2))
)

(defun custom-copy-line-or-region ()
	"Copy region or current line to BOTH kill-ring and system clipboard."
	(interactive)
	(let* ((text
			(if (use-region-p)
			(buffer-substring-no-properties (region-beginning) (region-end))
			(buffer-substring-no-properties
			(line-beginning-position)
			(line-beginning-position 2)))
		))
		;; Put into kill ring
		(kill-new text)

		;; Put into macOS system clipboard (ignore Emacs interprogram hooks)
		(with-temp-buffer
			(insert text)
			(call-process-region (point-min) (point-max) "pbcopy")
		)

		(message "Copied: %s" (if (use-region-p) "region" "line"))
	)
)

(defun custom-cut-line-or-region ()
	"If region is active, kill it. Otherwise, kill the current line."
	(interactive)
	(if (use-region-p)
		(kill-region (region-beginning) (region-end))
		(kill-whole-line)
	)
)

(defun my/search-region ()
	"Start isearch for current region or symbol, starting at its beginning."
	(interactive)
	(let* ((text (if (use-region-p)
                   (buffer-substring-no-properties (region-beginning) (region-end))
                 (thing-at-point 'symbol t))
		))
	    (when text
			(deactivate-mark)
			(unless (use-region-p)
				(let ((bounds (bounds-of-thing-at-point 'symbol)))
					(when bounds
						(goto-char (car bounds)))
				)
			)
			(isearch-mode t)
			(isearch-yank-string text)
		)
	)
)


(menu-bar-mode -1)   ;; Remove the "File Edit Options" menu
;; (tool-bar-mode -1)   ;; Remove the row of icons
;; (scroll-bar-mode -1) ;; Remove the scroll bars for a truly clean look

;; Disable word wrap (truncate lines) globally
(setq-default truncate-lines t)

;; Enable line numbers globally
(global-display-line-numbers-mode t)

;; Disable line numbers for specific modes where they don't make sense
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                treemacs-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))
(global-hl-line-mode t)


(setq dirvish-attributes '(file-size vcs-state icons collapse subtree-state))


(with-eval-after-load 'org
  (my/org-checkbox-pretty-and-colored)
  (setq org-todo-keyword-faces
        '(("TODO" . (:foreground "white" :weight bold))
          ("DONE" . (:foreground "green" :weight bold))))

  (define-key org-mode-map (kbd "C-c -") #'my/org-checkbox-set-indeterminate)
		(add-hook 'org-mode-hook (lambda ()
			;; (setq org-enforce-todo-dependencies nil)
			;; (setq org-enforce-todo-checkbox-dependencies nil)
			;; (setq org-checkbox-hierarchical-statistics nil)

			(my/org-checkbox-pretty-and-colored)
			;; (set-face-attribute 'org-default nil :foreground "#a877bf")
			;; (buffer-face-set 'org-default)
			(define-key org-mode-map (kbd "M-<down>") 'custom-move-down-7-lines)
			(define-key org-mode-map (kbd "M-<up>") 'custom-move-up-7-lines)
			(define-key org-mode-map (kbd "M-}") 'custom-move-down-7-lines)
			(define-key org-mode-map (kbd "M-{") 'custom-move-up-7-lines)
			;; (company-mode -1)
		))
)

;; Disable the "dumb" checkbox behavior
(setq org-enforce-todo-checkbox-dependencies nil)
(setq org-enforce-todo-dependencies nil)
(setq org-checkbox-statistics-intermediate-state t)
(setq org-startup-indented t) ;; <-- this enables org-indent-mode on startup
(setq org-indent-indentation-per-level 4)

;; Enable mouse support in the terminal
(unless (display-graphic-p)
  (xterm-mouse-mode 1)
  (global-set-key (kbd "<mouse-4>") 'scroll-down-line)
  (global-set-key (kbd "<mouse-5>") 'scroll-up-line)
)
;; Enable mouse wheel scrolling
(setq mouse-wheel-mode t)
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; one line at a time
(setq mouse-wheel-progressive-speed nil)            ;; don't accelerate
(setq mouse-wheel-follow-mouse 't)                  ;; scroll window under mouse


;; 1. Disable backup files (the ones ending in ~)
(setq make-backup-files nil)
;; 2. Disable auto-save files (the ones wrapped in #)
(setq auto-save-default nil)
;; 3. Disable lock files (the ones starting with .#)
;; These prevent two people from editing the same file;
;; if you're the only one on your machine, you don't need them.
(setq create-lockfiles nil)
;; Reload file automatically if changed outside of emacs
(global-auto-revert-mode t)

;; Disable the "Modified buffers exist" prompt when exiting Emacs
(setq confirm-kill-emacs nil)
;; Force Emacs to quit without asking to save other buffers
;; (defun my-force-kill-emacs ()
;;   "Kill Emacs without asking to save modified buffers."
;;   (interactive)
;;   (save-buffers-kill-emacs t))
;; ;; Rebind the exit key (C-x C-c) to your new forced function
;; (global-set-key (kbd "C-x C-c") #'my-force-kill-emacs)


;; Remember cursor location upon reopening file
(save-place-mode 1)
;; (add-hook 'find-file-hook (lambda () (recenter-top-bottom)) t)
;; ;; Bonus, smooth scrolling
;; (setq scroll-margin 5           ; Start scrolling when 5 lines from top/bottom
;;       scroll-step 1             ; Scroll 1 line at a time
;;       scroll-conservatively 101) ; Never jump more than 1 line


;; Decode Ghostty's Cmd+Enter sequence
(define-key input-decode-map "\e[111;9z" [cmd-enter])
;; Bind Cmd+Enter
(global-set-key [cmd-enter] #'insert-line)
;; Decode Ghostty's Cmd+Shift+Enter sequence
(define-key input-decode-map "\e[111;10z" [cmd-shift-enter])
;; Bind it
(global-set-key [cmd-shift-enter] #'insert-line-above)

;; Decode Ghostty's custom Cmd+D sequence
(define-key input-decode-map "\e[110;9z" [cmd-d])
;; Bind Cmd+D to duplicate-line
(global-set-key [cmd-d] #'duplicate-line)

;; Decode the Ghostty sequence
(define-key input-decode-map "\e[114;9z" [cmd-j])
;; Bind it to join-line
(global-set-key [cmd-j] 'custom-join-lines)

(define-key input-decode-map "\e[119;9z" [cmd-s])
(global-set-key [cmd-s]
  (lambda () (interactive) (execute-kbd-macro (kbd "C-x C-s")))
)

;; Decode the Ghostty sequence
(define-key input-decode-map "\e[122;9z" [cmd-e])
;; Bind it to select word under cursor
(global-set-key [cmd-e] 'my/search-region)

;; Decode Ghostty Cmd+C sequence
(define-key input-decode-map "\e[118;9z" [cmd-c])
;; Make Cmd+C behave like M-w
(global-set-key [cmd-c] 'custom-copy-line-or-region)

;; Decode the Ghostty Cmd+X escape sequence
(define-key input-decode-map "\e[120;9z" [cmd-x])
;; Map it to the same thing as C-w (kill-region)
;; (global-set-key [cmd-x] (key-binding (kbd "C-w")))
(global-set-key [cmd-x] 'custom-cut-line-or-region)

;; Decode Ghostty sequence for Cmd+Ctrl+Up
(define-key input-decode-map "\e[115;9z" [cmd-ctrl-up])
;; Decode Ghostty sequence for Cmd+Ctrl+Down
(define-key input-decode-map "\e[116;9z" [cmd-ctrl-down])
;; (use-package move-text
;;     :config
;;     ;; Move current line or region up/down
;;     (global-set-key [cmd-ctrl-up] 'move-text-up)
;;     (global-set-key [cmd-ctrl-down] 'move-text-down))
(use-package move-text
  :ensure t  ;; <--- Add this line to auto-install
  :config
  ;; Move current line or region up/down
  (global-set-key [cmd-ctrl-up] 'move-text-up)
  (global-set-key [cmd-ctrl-down] 'move-text-down))


(global-set-key (kbd "M-a") #'my/select-current-line-and-forward-line)

(global-set-key (kbd "M-q") #'delete-current-line)
(add-hook 'prog-mode-hook
	(lambda ()
		(local-set-key (kbd "M-q") #'delete-current-line))
)
;; Decode Ghostty sequence for Ctrl+Shift+Backspace
(define-key input-decode-map "\e[117;9z" [C-S-backspace])
;; Bind it to delete-current-line
(global-set-key [C-S-backspace] #'delete-current-line)


;; The only way to get an actual command/super is to use GUI Emacs
;; We can't map to Esc as a prefix, because that is Alt's default mapping
;; So instead, we're going to map to a uniq charater string
(define-key input-decode-map "\e[108;9z" [cmd-z])
(global-set-key [cmd-z] 'undo)
;; Redo: interpret ESC [109;9z as [cmd-shift-z]
(define-key input-decode-map "\e[109;9z" [cmd-shift-z])
;; Bind it to redo
(global-set-key [cmd-shift-z] 'undo-redo)

(define-key global-map (kbd "C-v") #'my/scroll-half-page-down)
(define-key global-map (kbd "M-v") #'my/scroll-half-page-up)

;; (define-key org-mode-map (kbd "M-<down>") 'custom-move-down-7-lines)
;; (define-key org-mode-map (kbd "M-<up>") 'custom-move-up-7-lines)
;; (define-key org-mode-map (kbd "M-}") 'custom-move-down-7-lines)
;; (define-key org-mode-map (kbd "M-{") 'custom-move-up-7-lines)

(global-set-key (kbd "M-<up>") 'custom-move-up-7-lines)
(global-set-key (kbd "M-<down>") 'custom-move-down-7-lines)
(global-set-key (kbd "M-{") 'custom-move-up-7-lines)
(global-set-key (kbd "M-}") 'custom-move-down-7-lines)
(global-set-key (kbd "M-i") 'custom-move-up-7-lines)
(global-set-key (kbd "M-k") 'custom-move-down-7-lines)

(global-unset-key (kbd "M-z"))
(global-set-key (kbd "M-z") #'my/comment-or-region)
(global-set-key (kbd "C-d") #'my/delete-or-region)

(global-set-key (kbd "C-S-<up>") 'mc/mark-previous-like-this)
(global-set-key (kbd "C-S-<down>") 'mc/mark-next-like-this)

(global-set-key (kbd "C-t") 'projectile-find-file)


(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages nil)
 '(safe-local-variable-directories '("/Users/michaelschneider/appropos/envoy-web/")))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
