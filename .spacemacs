;; -*- mode: emacs-lisp; lexical-binding: t -*-
;; This file is loaded by Spacemacs at startup.
;; It must be stored in your home directory.

(defun dotspacemacs/layers ()
  "Layer configuration:
This function should only modify configuration layer settings."

  (setq-default
   ;; Base distribution to use. This is a layer contained in the directory
   ;; `+distribution'. For now available distributions are `spacemacs-base'
   ;; or `spacemacs'. (default 'spacemacs)
   dotspacemacs-distribution 'spacemacs

   ;; Lazy installation of layers (i.e. layers are installed only when a file
   ;; with a supported type is opened). Possible values are `all', `unused'
   ;; and `nil'. `unused' will lazy install only unused layers (i.e. layers
   ;; not listed in variable `dotspacemacs-configuration-layers'), `all' will
   ;; lazy install any layer that support lazy installation even the layers
   ;; listed in `dotspacemacs-configuration-layers'. `nil' disable the lazy
   ;; installation feature and you have to explicitly list a layer in the
   ;; variable `dotspacemacs-configuration-layers' to install it.
   ;; (default 'unused)
   dotspacemacs-enable-lazy-installation 'unused

   ;; If non-nil then Spacemacs will ask for confirmation before installing
   ;; a layer lazily. (default t)
   dotspacemacs-ask-for-lazy-installation t

   ;; List of additional paths where to look for configuration layers.
   ;; Paths must have a trailing slash (i.e. "~/.mycontribs/")
   dotspacemacs-configuration-layer-path '()

   ;; List of configuration layers to load.
   dotspacemacs-configuration-layers
   '(toml
     html
     typescript
     javascript
     ;; ----------------------------------------------------------------
     ;; Example of useful layers you may want to use right away.
     ;; Uncomment some layer names and press `SPC f e R' (Vim style) or
     ;; `M-m f e R' (Emacs style) to install them.
     ;; ----------------------------------------------------------------
     (auto-completion :variables
        auto-completion-enable-snippets-in-popup t)
     ;; better-defaults
     emacs-lisp
     (git :variables
        git-enable-magit-delta-plugin t
        git-enable-code-review nil)
     helm
     ;; lsp
     ;; markdown
     multiple-cursors
     ;; org
     ;; (shell :variables
     ;;        shell-default-height 30
     ;;        shell-default-position 'bottom)
     ;; spell-checking
     ;; syntax-checking
     ;; version-control
     treemacs

     (typescript :variables
        typescript-backend 'lsp)
     (javascript :variables
        javascript-backend 'lsp)
     (syntax-checking)

     ;;  (doom-themes :variables ;; This was throwing an error in *Messages*
     ;;               doom-themes-enable-bold t
     ;;               doom-themes-enable-italic t
     ;;               )
     )


   ;; List of additional packages that will be installed without being wrapped
   ;; in a layer (generally the packages are installed only and should still be
   ;; loaded using load/require/use-package in the user-config section below in
   ;; this file). If you need some configuration for these packages, then
   ;; consider creating a layer. You can also put the configuration in
   ;; `dotspacemacs/user-config'. To use a local version of a package, use the
   ;; `:location' property: '(your-package :location "~/path/to/your-package/")
   ;; Also include the dependencies as they will not be resolved automatically.
   dotspacemacs-additional-packages '(
      doom-themes ;; this ones legit
      web-mode
      move-text
   )

   ;; A list of packages that cannot be updated.
   dotspacemacs-frozen-packages '()

   ;; A list of packages that will not be installed and loaded.
   dotspacemacs-excluded-packages '(code-review)

   ;; Defines the behaviour of Spacemacs when installing packages.
   ;; Possible values are `used-only', `used-but-keep-unused' and `all'.
   ;; `used-only' installs only explicitly used packages and deletes any unused
   ;; packages as well as their unused dependencies. `used-but-keep-unused'
   ;; installs only the used packages but won't delete unused ones. `all'
   ;; installs *all* packages supported by Spacemacs and never uninstalls them.
   ;; (default is `used-only')
   dotspacemacs-install-packages 'used-only)
  )

(defun dotspacemacs/init ()
  "Initialization:
This function is called at the very beginning of Spacemacs startup,
before layer configuration.
It should only modify the values of Spacemacs settings."
  ;; This setq-default sexp is an exhaustive list of all the supported
  ;; spacemacs settings.
  (setq-default
   ;; Maximum allowed time in seconds to contact an ELPA repository.
   ;; (default 5)
   dotspacemacs-elpa-timeout 5

   ;; Set `gc-cons-threshold' and `gc-cons-percentage' when startup finishes.
   ;; This is an advanced option and should not be changed unless you suspect
   ;; performance issues due to garbage collection operations.
   ;; (default '(100000000 0.1))
   dotspacemacs-gc-cons '(100000000 0.1)

   ;; Set `read-process-output-max' when startup finishes.
   ;; This defines how much data is read from a foreign process.
   ;; Setting this >= 1 MB should increase performance for lsp servers
   ;; in emacs 27.
   ;; (default (* 1024 1024))
   dotspacemacs-read-process-output-max (* 1024 1024)

   ;; If non-nil then Spacelpa repository is the primary source to install
   ;; a locked version of packages. If nil then Spacemacs will install the
   ;; latest version of packages from MELPA. Spacelpa is currently in
   ;; experimental state please use only for testing purposes.
   ;; (default nil)
   dotspacemacs-use-spacelpa nil

   ;; If non-nil then verify the signature for downloaded Spacelpa archives.
   ;; (default t)
   dotspacemacs-verify-spacelpa-archives t

   ;; If non-nil then spacemacs will check for updates at startup
   ;; when the current branch is not `develop'. Note that checking for
   ;; new versions works via git commands, thus it calls GitHub services
   ;; whenever you start Emacs. (default nil)
   dotspacemacs-check-for-update nil

   ;; If non-nil, a form that evaluates to a package directory. For example, to
   ;; use different package directories for different Emacs versions, set this
   ;; to `emacs-version'. (default 'emacs-version)
   dotspacemacs-elpa-subdirectory 'emacs-version

   ;; One of `vim', `emacs' or `hybrid'.
   ;; `hybrid' is like `vim' except that `insert state' is replaced by the
   ;; `hybrid state' with `emacs' key bindings. The value can also be a list
   ;; with `:variables' keyword (similar to layers). Check the editing styles
   ;; section of the documentation for details on available variables.
   ;; (default 'vim)
   dotspacemacs-editing-style 'emacs
   dotspacemacs-enable-evil-support nil

   ;; If non-nil show the version string in the Spacemacs buffer. It will
   ;; appear as (spacemacs version)@(emacs version)
   ;; (default t)
   dotspacemacs-startup-buffer-show-version nil

   ;; Specify the startup banner. Default value is `official', it displays
   ;; the official spacemacs logo. An integer value is the index of text
   ;; banner, `random' chooses a random text banner in `core/banners'
   ;; directory. A string value must be a path to an image format supported
   ;; by your Emacs build.
   ;; If the value is nil then no banner is displayed. (default 'official)
   dotspacemacs-startup-banner nil

   ;; Scale factor controls the scaling (size) of the startup banner. Default
   ;; value is `auto' for scaling the logo automatically to fit all buffer
   ;; contents, to a maximum of the full image height and a minimum of 3 line
   ;; heights. If set to a number (int or float) it is used as a constant
   ;; scaling factor for the default logo size.
   dotspacemacs-startup-banner-scale 'auto

   ;; List of items to show in startup buffer or an association list of
   ;; the form `(list-type . list-size)`. If nil then it is disabled.
   ;; Possible values for list-type are:
   ;; `recents' `recents-by-project' `bookmarks' `projects' `agenda' `todos'.
   ;; List sizes may be nil, in which case
   ;; `spacemacs-buffer-startup-lists-length' takes effect.
   ;; The exceptional case is `recents-by-project', where list-type must be a
   ;; pair of numbers, e.g. `(recents-by-project . (7 .  5))', where the first
   ;; number is the project limit and the second the limit on the recent files
   ;; within a project.
   dotspacemacs-startup-lists '()

   ;; True if the home buffer should respond to resize events. (default t)
   dotspacemacs-startup-buffer-responsive nil

   ;; Show numbers before the startup list lines. (default t)
   dotspacemacs-show-startup-list-numbers nil

   ;; The minimum delay in seconds between number key presses. (default 0.4)
   dotspacemacs-startup-buffer-multi-digit-delay 0.4

   ;; If non-nil, show file icons for entries and headings on Spacemacs home buffer.
   ;; This has no effect in terminal or if "nerd-icons" package or the font
   ;; is not installed. (default nil)
   dotspacemacs-startup-buffer-show-icons nil

   ;; Default major mode for a new empty buffer. Possible values are mode
   ;; names such as `text-mode'; and `nil' to use Fundamental mode.
   ;; (default `text-mode')
   dotspacemacs-new-empty-buffer-major-mode 'text-mode

   ;; Default major mode of the scratch buffer (default `text-mode')
   dotspacemacs-scratch-mode 'text-mode

   ;; If non-nil, *scratch* buffer will be persistent. Things you write down in
   ;; *scratch* buffer will be saved and restored automatically.
   dotspacemacs-scratch-buffer-persistent nil

   ;; If non-nil, `kill-buffer' on *scratch* buffer
   ;; will bury it instead of killing.
   dotspacemacs-scratch-buffer-unkillable nil

   ;; Initial message in the scratch buffer, such as "Welcome to Spacemacs!"
   ;; (default nil)
   dotspacemacs-initial-scratch-message nil

   ;; List of themes, the first of the list is loaded when spacemacs starts.
   ;; Press `SPC T n' to cycle to the next theme in the list (works great
   ;; with 2 themes variants, one dark and one light). A theme from external
   ;; package can be defined with `:package', or a theme can be defined with
   ;; `:location' to download the theme package, refer the themes section in
   ;; DOCUMENTATION.org for the full theme specifications.
   dotspacemacs-themes '(spacemacs-dark
                         spacemacs-light)

   ;; Set the theme for the Spaceline. Supported themes are `spacemacs',
   ;; `all-the-icons', `custom', `doom', `vim-powerline' and `vanilla'. The
   ;; first three are spaceline themes. `doom' is the doom-emacs mode-line.
   ;; `vanilla' is default Emacs mode-line. `custom' is a user defined themes,
   ;; refer to the DOCUMENTATION.org for more info on how to create your own
   ;; spaceline theme. Value can be a symbol or list with additional properties.
   ;; (default '(spacemacs :separator wave :separator-scale 1.5))
   dotspacemacs-mode-line-theme '(spacemacs :separator wave :separator-scale 1.5)

   ;; If non-nil the cursor color matches the state color in GUI Emacs.
   ;; (default t)
   dotspacemacs-colorize-cursor-according-to-state t

   ;; Default font or prioritized list of fonts. This setting has no effect when
   ;; running Emacs in terminal. The font set here will be used for default and
   ;; fixed-pitch faces. The `:size' can be specified as
   ;; a non-negative integer (pixel size), or a floating-point (point size).
   ;; Point size is recommended, because it's device independent. (default 10.0)
   dotspacemacs-default-font '("Source Code Pro"
                               :size 10.0
                               :weight normal
                               :width normal)

   ;; Default icons font, it can be `all-the-icons' or `nerd-icons'.
   dotspacemacs-default-icons-font 'all-the-icons

   ;; The leader key (default "SPC")
   dotspacemacs-leader-key "SPC"

   ;; The key used for Emacs commands `M-x' (after pressing on the leader key).
   ;; (default "SPC")
   dotspacemacs-emacs-command-key "SPC"

   ;; The key used for Vim Ex commands (default ":")
   dotspacemacs-ex-command-key ":"

   ;; The leader key accessible in `emacs state' and `insert state'
   ;; (default "M-m")
   dotspacemacs-emacs-leader-key "C-,"

   ;; Major mode leader key is a shortcut key which is the equivalent of
   ;; pressing `<leader> m`. Set it to `nil` to disable it. (default ",")
   dotspacemacs-major-mode-leader-key ","

   ;; Major mode leader key accessible in `emacs state' and `insert state'.
   ;; (default "C-M-m" for terminal mode, "M-<return>" for GUI mode).
   ;; Thus M-RET should work as leader key in both GUI and terminal modes.
   ;; C-M-m also should work in terminal mode, but not in GUI mode.
   dotspacemacs-major-mode-emacs-leader-key (if window-system "M-<return>" "C-M-m")

   ;; These variables control whether separate commands are bound in the GUI to
   ;; the key pairs `C-i', `TAB' and `C-m', `RET'.
   ;; Setting it to a non-nil value, allows for separate commands under `C-i'
   ;; and TAB or `C-m' and `RET'.
   ;; In the terminal, these pairs are generally indistinguishable, so this only
   ;; works in the GUI. (default nil)
   dotspacemacs-distinguish-gui-tab nil

   ;; Name of the default layout (default "Default")
   dotspacemacs-default-layout-name "Default"

   ;; If non-nil the default layout name is displayed in the mode-line.
   ;; (default nil)
   dotspacemacs-display-default-layout nil

   ;; If non-nil then the last auto saved layouts are resumed automatically upon
   ;; start. (default nil)
   dotspacemacs-auto-resume-layouts nil

   ;; If non-nil, auto-generate layout name when creating new layouts. Only has
   ;; effect when using the "jump to layout by number" commands. (default nil)
   dotspacemacs-auto-generate-layout-names nil

   ;; Size (in MB) above which spacemacs will prompt to open the large file
   ;; literally to avoid performance issues. Opening a file literally means that
   ;; no major mode or minor modes are active. (default is 1)
   dotspacemacs-large-file-size 1

   ;; Location where to auto-save files. Possible values are `original' to
   ;; auto-save the file in-place, `cache' to auto-save the file to another
   ;; file stored in the cache directory and `nil' to disable auto-saving.
   ;; (default 'cache)
   dotspacemacs-auto-save-file-location 'cache

   ;; Maximum number of rollback slots to keep in the cache. (default 5)
   dotspacemacs-max-rollback-slots 5

   ;; If non-nil, the paste transient-state is enabled. While enabled, after you
   ;; paste something, pressing `C-j' and `C-k' several times cycles through the
   ;; elements in the `kill-ring'. (default nil)
   dotspacemacs-enable-paste-transient-state nil

   ;; Which-key delay in seconds. The which-key buffer is the popup listing
   ;; the commands bound to the current keystroke sequence. (default 0.4)
   dotspacemacs-which-key-delay 0.4

   ;; Which-key frame position. Possible values are `right', `bottom' and
   ;; `right-then-bottom'. right-then-bottom tries to display the frame to the
   ;; right; if there is insufficient space it displays it at the bottom.
   ;; It is also possible to use a posframe with the following cons cell
   ;; `(posframe . position)' where position can be one of `center',
   ;; `top-center', `bottom-center', `top-left-corner', `top-right-corner',
   ;; `top-right-corner', `bottom-left-corner' or `bottom-right-corner'
   ;; (default 'bottom)
   dotspacemacs-which-key-position 'bottom

   ;; Control where `switch-to-buffer' displays the buffer. If nil,
   ;; `switch-to-buffer' displays the buffer in the current window even if
   ;; another same-purpose window is available. If non-nil, `switch-to-buffer'
   ;; displays the buffer in a same-purpose window even if the buffer can be
   ;; displayed in the current window. (default nil)
   dotspacemacs-switch-to-buffer-prefers-purpose nil

   ;; Whether side windows (such as those created by treemacs or neotree)
   ;; are kept or minimized by `spacemacs/toggle-maximize-window' (SPC w m).
   ;; (default t)
   dotspacemacs-maximize-window-keep-side-windows t

   ;; If nil, no load-hints enabled. If t, enable the `load-hints' which will
   ;; put the most likely path on the top of `load-path' to reduce walking
   ;; through the whole `load-path'. It's an experimental feature to speedup
   ;; Spacemacs on Windows. Refer the FAQ.org "load-hints" session for details.
   dotspacemacs-enable-load-hints nil

   ;; If t, enable the `package-quickstart' feature to avoid full package
   ;; loading, otherwise no `package-quickstart' attemption (default nil).
   ;; Refer the FAQ.org "package-quickstart" section for details.
   dotspacemacs-enable-package-quickstart nil

   ;; If non-nil a progress bar is displayed when spacemacs is loading. This
   ;; may increase the boot time on some systems and emacs builds, set it to
   ;; nil to boost the loading time. (default t)
   dotspacemacs-loading-progress-bar t

   ;; If non-nil the frame is fullscreen when Emacs starts up. (default nil)
   ;; (Emacs 24.4+ only)
   dotspacemacs-fullscreen-at-startup nil

   ;; If non-nil `spacemacs/toggle-fullscreen' will not use native fullscreen.
   ;; Use to disable fullscreen animations in OSX. (default nil)
   dotspacemacs-fullscreen-use-non-native nil

   ;; If non-nil the frame is maximized when Emacs starts up.
   ;; Takes effect only if `dotspacemacs-fullscreen-at-startup' is nil.
   ;; (default t) (Emacs 24.4+ only)
   dotspacemacs-maximized-at-startup t

   ;; If non-nil the frame is undecorated when Emacs starts up. Combine this
   ;; variable with `dotspacemacs-maximized-at-startup' to obtain fullscreen
   ;; without external boxes. Also disables the internal border. (default nil)
   dotspacemacs-undecorated-at-startup nil

   ;; A value from the range (0..100), in increasing opacity, which describes
   ;; the transparency level of a frame when it's active or selected.
   ;; Transparency can be toggled through `toggle-transparency'. (default 90)
   dotspacemacs-active-transparency 90

   ;; A value from the range (0..100), in increasing opacity, which describes
   ;; the transparency level of a frame when it's inactive or deselected.
   ;; Transparency can be toggled through `toggle-transparency'. (default 90)
   dotspacemacs-inactive-transparency 90

   ;; A value from the range (0..100), in increasing opacity, which describes the
   ;; transparency level of a frame background when it's active or selected. Transparency
   ;; can be toggled through `toggle-background-transparency'. (default 90)
   dotspacemacs-background-transparency 90

   ;; If non-nil show the titles of transient states. (default t)
   dotspacemacs-show-transient-state-title t

   ;; If non-nil show the color guide hint for transient state keys. (default t)
   dotspacemacs-show-transient-state-color-guide t

   ;; If non-nil unicode symbols are displayed in the mode line.
   ;; If you use Emacs as a daemon and wants unicode characters only in GUI set
   ;; the value to quoted `display-graphic-p'. (default t)
   dotspacemacs-mode-line-unicode-symbols t

   ;; If non-nil smooth scrolling (native-scrolling) is enabled. Smooth
   ;; scrolling overrides the default behavior of Emacs which recenters point
   ;; when it reaches the top or bottom of the screen. (default t)
   dotspacemacs-smooth-scrolling t

   ;; Show the scroll bar while scrolling. The auto hide time can be configured
   ;; by setting this variable to a number. (default t)
   dotspacemacs-scroll-bar-while-scrolling t

   ;; Control line numbers activation.
   ;; If set to `t', `relative' or `visual' then line numbers are enabled in all
   ;; `prog-mode' and `text-mode' derivatives. If set to `relative', line
   ;; numbers are relative. If set to `visual', line numbers are also relative,
   ;; but only visual lines are counted. For example, folded lines will not be
   ;; counted and wrapped lines are counted as multiple lines.
   ;; This variable can also be set to a property list for finer control:
   ;; '(:relative nil
   ;;   :visual nil
   ;;   :disabled-for-modes dired-mode
   ;;                       doc-view-mode
   ;;                       markdown-mode
   ;;                       org-mode
   ;;                       pdf-view-mode
   ;;                       text-mode
   ;;   :size-limit-kb 1000)
   ;; When used in a plist, `visual' takes precedence over `relative'.
   ;; (default nil)
   dotspacemacs-line-numbers t

   ;; Code folding method. Possible values are `evil', `origami' and `vimish'.
   ;; (default 'evil)
   dotspacemacs-folding-method 'origami

   ;; If non-nil and `dotspacemacs-activate-smartparens-mode' is also non-nil,
   ;; `smartparens-strict-mode' will be enabled in programming modes.
   ;; (default nil)
   dotspacemacs-smartparens-strict-mode nil

   ;; If non-nil smartparens-mode will be enabled in programming modes.
   ;; (default t)
   dotspacemacs-activate-smartparens-mode t

   ;; If non-nil pressing the closing parenthesis `)' key in insert mode passes
   ;; over any automatically added closing parenthesis, bracket, quote, etc...
   ;; This can be temporary disabled by pressing `C-q' before `)'. (default nil)
   dotspacemacs-smart-closing-parenthesis nil

   ;; Select a scope to highlight delimiters. Possible values are `any',
   ;; `current', `all' or `nil'. Default is `all' (highlight any scope and
   ;; emphasis the current one). (default 'all)
   dotspacemacs-highlight-delimiters 'all

   ;; If non-nil, start an Emacs server if one is not already running.
   ;; (default nil)
   dotspacemacs-enable-server nil

   ;; Set the emacs server socket location.
   ;; If nil, uses whatever the Emacs default is, otherwise a directory path
   ;; like \"~/.emacs.d/server\". It has no effect if
   ;; `dotspacemacs-enable-server' is nil.
   ;; (default nil)
   dotspacemacs-server-socket-dir nil

   ;; If non-nil, advise quit functions to keep server open when quitting.
   ;; (default nil)
   dotspacemacs-persistent-server nil

   ;; List of search tool executable names. Spacemacs uses the first installed
   ;; tool of the list. Supported tools are `rg', `ag', `ack' and `grep'.
   ;; (default '("rg" "ag" "ack" "grep"))
   dotspacemacs-search-tools '("rg" "ag" "ack" "grep")

   ;; The backend used for undo/redo functionality. Possible values are
   ;; `undo-fu', `undo-redo' and `undo-tree' see also `evil-undo-system'.
   ;; Note that saved undo history does not get transferred when changing
   ;; your undo system. The default is currently `undo-fu' as `undo-tree'
   ;; is not maintained anymore and `undo-redo' is very basic."
   dotspacemacs-undo-system 'undo-fu

   ;; Format specification for setting the frame title.
   ;; %a - the `abbreviated-file-name', or `buffer-name'
   ;; %t - `projectile-project-name'
   ;; %I - `invocation-name'
   ;; %S - `system-name'
   ;; %U - contents of $USER
   ;; %b - buffer name
   ;; %f - visited file name
   ;; %F - frame name
   ;; %s - process status
   ;; %p - percent of buffer above top of window, or Top, Bot or All
   ;; %P - percent of buffer above bottom of window, perhaps plus Top, or Bot or All
   ;; %m - mode name
   ;; %n - Narrow if appropriate
   ;; %z - mnemonics of buffer, terminal, and keyboard coding systems
   ;; %Z - like %z, but including the end-of-line format
   ;; If nil then Spacemacs uses default `frame-title-format' to avoid
   ;; performance issues, instead of calculating the frame title by
   ;; `spacemacs/title-prepare' all the time.
   ;; (default "%I@%S")
   dotspacemacs-frame-title-format "%I@%S"

   ;; Format specification for setting the icon title format
   ;; (default nil - same as frame-title-format)
   dotspacemacs-icon-title-format nil

   ;; Color highlight trailing whitespace in all prog-mode and text-mode derived
   ;; modes such as c++-mode, python-mode, emacs-lisp, html-mode, rst-mode etc.
   ;; (default t)
   dotspacemacs-show-trailing-whitespace t

   ;; Delete whitespace while saving buffer. Possible values are `all'
   ;; to aggressively delete empty line and long sequences of whitespace,
   ;; `trailing' to delete only the whitespace at end of lines, `changed' to
   ;; delete only whitespace for changed lines or `nil' to disable cleanup.
   ;; The variable `global-spacemacs-whitespace-cleanup-modes' controls
   ;; which major modes have whitespace cleanup enabled or disabled
   ;; by default.
   ;; (default nil)
   dotspacemacs-whitespace-cleanup nil

   ;; If non-nil activate `clean-aindent-mode' which tries to correct
   ;; virtual indentation of simple modes. This can interfere with mode specific
   ;; indent handling like has been reported for `go-mode'.
   ;; If it does deactivate it here.
   ;; (default t)
   dotspacemacs-use-clean-aindent-mode t

   ;; Accept SPC as y for prompts if non-nil. (default nil)
   dotspacemacs-use-SPC-as-y nil

   ;; If non-nil shift your number row to match the entered keyboard layout
   ;; (only in insert state). Currently supported keyboard layouts are:
   ;; `qwerty-us', `qwertz-de' and `querty-ca-fr'.
   ;; New layouts can be added in `spacemacs-editing' layer.
   ;; (default nil)
   dotspacemacs-swap-number-row nil

   ;; Either nil or a number of seconds. If non-nil zone out after the specified
   ;; number of seconds. (default nil)
   dotspacemacs-zone-out-when-idle nil

   ;; Run `spacemacs/prettify-org-buffer' when
   ;; visiting README.org files of Spacemacs.
   ;; (default nil)
   dotspacemacs-pretty-docs nil

   ;; If nil the home buffer shows the full path of agenda items
   ;; and todos. If non-nil only the file name is shown.
   dotspacemacs-home-shorten-agenda-source nil

   dotspacemacs-enable-clipboard t

   ;; If non-nil then byte-compile some of Spacemacs files.
   dotspacemacs-byte-compile nil)

  (setq inhibit-startup-screen t)
  (setq initial-buffer-choice t)
  )

(defun dotspacemacs/user-env ()
  "Environment variables setup.
This function defines the environment variables for your Emacs session. By
default it calls `spacemacs/load-spacemacs-env' which loads the environment
variables declared in `~/.spacemacs.env' or `~/.spacemacs.d/.spacemacs.env'.
See the header of this file for more information."
  (spacemacs/load-spacemacs-env)
  )

(defun dotspacemacs/user-init ()
  "Initialization for user code:
This function is called immediately after `dotspacemacs/init', before layer
configuration.
It is mostly for variables that should be set before packages are loaded.
If you are unsure, try setting them in `dotspacemacs/user-config' first."
  )

(defun dotspacemacs/user-config ()
  "Configuration for user code:
This function is called at the very end of Spacemacs startup, after layer
configuration.
Put your configuration code here, except for variables that should be set
before packages are loaded."

  ;; --- Disable code-review entirely (Spacemacs bug workaround) ---
  (with-eval-after-load 'core-configuration-layer
    (advice-add 'configuration-layer//install-package
                :around
                (lambda (orig-fun pkg &rest args)
                  (unless (eq pkg 'code-review)
                    (apply orig-fun pkg args)))))

  (defun copy-to-osx (text &optional push)
    (let ((process-connection-type nil))
      (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
        (process-send-string proc text)
        (process-send-eof proc)))
    )

  (defun paste-from-osx ()
    (shell-command-to-string "pbpaste")
    )

  (setq interprogram-cut-function 'copy-to-osx)
  (setq interprogram-paste-function 'paste-from-osx)

  ;; Unset Spacemacs' default C-t binding
  (global-unset-key (kbd "C-t"))
  ;; Rebind C-t to helm-projectile-find-file
  (global-set-key (kbd "C-t") #'helm-projectile-find-file)

  ;; Decode Ghostty's custom Cmd+Shift+F sequence
  (define-key input-decode-map "\e[113;9z" [cmd-shift-f])
  ;; Bind it to helm-projectile-grep
  (global-set-key [cmd-shift-f] #'helm-projectile-rg)

  ;; The only way to get an actual command/super is to use GUI Emacs
  ;; We can't map to Esc as a prefix, because that is Alt's default mapping
  ;; So instead, we're going to map to a uniq charater string
  (define-key input-decode-map "\e[108;9z" [cmd-z])
  (global-set-key [cmd-z] 'undo)

  ;; Redo: interpret ESC [109;9z as [cmd-shift-z]
  (define-key input-decode-map "\e[109;9z" [cmd-shift-z])
  ;; Bind it to redo
  (global-set-key [cmd-shift-z] 'undo-redo)

  ;; (global-set-key (kbd "M-q") 'delete-current-line)
  (define-key global-map (kbd "M-q") #'delete-current-line)

  (global-unset-key (kbd "C-k"))
  ;; Restore vanilla Emacs kill-line
  (global-set-key (kbd "C-k") 'kill-line)

  ;; Decode the Ghostty sequence
  (define-key input-decode-map "\e[114;9z" [cmd-j])
  ;; Bind it to join-line
  (global-set-key [cmd-j] 'custom-join-lines)

  (global-set-key (kbd "M-a") #'my/select-current-line-and-forward-line)

  ;; Decode Ghostty's Cmd+Enter sequence
  (define-key input-decode-map "\e[111;9z" [cmd-enter])
  ;; Bind Cmd+Enter
  (global-set-key [cmd-enter] #'insert-line)

  ;; Decode Ghostty's custom Cmd+D sequence
  (define-key input-decode-map "\e[110;9z" [cmd-d])
  ;; Bind Cmd+D to duplicate-line
  (global-set-key [cmd-d] #'duplicate-line)


  ;; Decode Ghostty sequence for Cmd+Ctrl+Up
  (define-key input-decode-map "\e[115;9z" [cmd-ctrl-up])
  ;; Decode Ghostty sequence for Cmd+Ctrl+Down
  (define-key input-decode-map "\e[116;9z" [cmd-ctrl-down])
  (use-package move-text
    :config
    ;; Move current line or region up/down
    (global-set-key [cmd-ctrl-up] 'move-text-up)
    (global-set-key [cmd-ctrl-down] 'move-text-down))

  (with-eval-after-load 'flycheck
    ;; disable jshint since we prefer eslint checking
    (setq-default flycheck-disabled-checkers
                  (append flycheck-disabled-checkers
                          '(javascript-jshint)))

    ;; use eslint with js-mode, rjsx-mode, and tsx
    (flycheck-add-mode 'javascript-eslint 'js-mode)
    (flycheck-add-mode 'javascript-eslint 'rjsx-mode)
    (flycheck-add-mode 'javascript-eslint 'typescript-tsx-mode)

    ;; point flycheck at project-local eslint if available
    (defun my/use-eslint-from-node-modules ()
      (let* ((root (locate-dominating-file
                    (or (buffer-file-name) default-directory)
                    "node_modules"))
             (eslint (and root
                          (expand-file-name "node_modules/.bin/eslint"
                                            root))))
        (when (and eslint (file-executable-p eslint))
          (setq-local flycheck-javascript-eslint-executable eslint))))
    (add-hook 'flycheck-mode-hook #'my/use-eslint-from-node-modules))

  ;; Center the screen on the current match after isearch jumps
  (add-hook 'isearch-update-post-hook
            (lambda ()
              (recenter)))

  (set-default 'truncate-lines t)

  (define-key prog-mode-map (kbd "M-p") #'my/insert-console-log-util)
  (global-set-key (kbd "M-p") #'my/insert-console-log-util)

  ;; Decode Ghostty sequence for Ctrl+Shift+Backspace
  (define-key input-decode-map "\e[117;9z" [C-S-backspace])
  ;; Bind it to delete-current-line
  (global-set-key [C-S-backspace] #'delete-current-line)

  ;; Force Emacs to assume truecolor in terminal
  (setenv "COLORTERM" "truecolor")
  (setq xterm-term-name "xterm-256color")

  (require 'doom-themes)

  ;; Optional but nice:
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)

  ;; Load one immediately
  (load-theme 'doom-one t)

  ;; Enable Doom's improved org-mode & visual bell tweaks (safe even if you don't use org)
  (doom-themes-org-config)

  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (set-face-attribute 'italic nil :slant 'italic)
  (set-face-attribute 'font-lock-comment-face nil :slant 'italic)

  (doom-themes-visual-bell-config)
  (doom-themes-org-config)

  ;; (setq cursor-type '(bar . 2))
  ;; (set-cursor-color "#0000ff") ;; gold/yellow
  ;; (add-hook 'after-load-theme-hook
  ;;         (lambda ()
  ;; (set-cursor-color "#00ffff")))

  (blink-cursor-mode 1)
  ;; (setq blink-cursor-interval 0.3)

  (spacemacs/set-leader-keys "bk" 'kill-this-buffer)
  (define-key global-map (kbd "C-x k")
              (lambda ()
                (interactive)
                (kill-buffer (current-buffer))))

  ;; Decode Ghostty Cmd+C sequence
  (define-key input-decode-map "\e[118;9z" [cmd-c])
  ;; Make Cmd+C behave like M-w
  ;; (global-set-key [cmd-c] #'kill-ring-save)
  (global-set-key [cmd-c] 'custom-copy-line-or-region)

  (define-key input-decode-map "\e[119;9z" [cmd-s])
  (global-set-key [cmd-s]
                  (lambda () (interactive) (execute-kbd-macro (kbd "C-x C-s"))))

  ;; Decode the Ghostty Cmd+X escape sequence
  (define-key input-decode-map "\e[120;9z" [cmd-x])
  ;; Map it to the same thing as C-w (kill-region)
  ;; (global-set-key [cmd-x] (key-binding (kbd "C-w")))
  (global-set-key [cmd-x] 'custom-cut-line-or-region)

  ;; Map Ghostty's custom Ctrl-, escape to real C-, in terminal Emacs
  (define-key input-decode-map "\e[121;9z" (kbd "C-,"))

  (global-set-key (kbd "C-y") 'custom-smart-yank)

  (global-set-key (kbd "M-<up>") 'custom-move-up-7-lines)
  (global-set-key (kbd "M-<down>") 'custom-move-down-7-lines)
  (global-set-key (kbd "M-}") 'custom-move-down-7-lines)
  (global-set-key (kbd "M-{") 'custom-move-up-7-lines)

  (defun my/insert-console-log-util ()
    "Insert my console.log util snippet."
    (interactive)
    (yas-expand-snippet
     "console.log('$1:');\nconsole.log(require('util').inspect($1, false, null));"))

  (global-unset-key (kbd "M-z"))
  (global-set-key (kbd "M-z") #'my/comment-or-region)

  ;; Remap C-d to our smarter delete function
  (global-set-key (kbd "C-d") #'my/delete-or-region)

  (with-eval-after-load 'web-mode
    ;; Set specific comment formats for different contexts within web-mode.
    (setq web-mode-comment-formats
          '(("java" . "/*")
            ("javascript" . "//")
            ("jsx" . "//")
            ("tsx" . "//")
            ("php" . "/*")))

    ;; Ensure that `comment-dwim` works correctly for JSX elements.
    (add-hook 'web-mode-hook
              (lambda ()
                (setq-local comment-start "//")
                (setq-local comment-end "")
                (setq-local comment-start-skip "//[ \t]*")))
    )

  (global-set-key (kbd "C-S-<up>") 'mc/mark-previous-like-this)
  (global-set-key (kbd "C-S-<down>") 'mc/mark-next-like-this)

  (with-eval-after-load 'js2-mode
    ;; Disable all built-in js2-mode warnings and strict checks
    (setq js2-mode-show-parse-errors nil)
    (setq js2-mode-show-strict-warnings nil)
    (setq js2-strict-missing-semi-warning nil)
    )

  (with-eval-after-load 'yasnippet
    (define-key yas-minor-mode-map (kbd "<tab>") 'my/tab-action)
    (define-key yas-minor-mode-map (kbd "TAB") 'my/tab-action)
  )

  (define-key input-decode-map "\e[122;9z" [cmd-e])
  (global-set-key [cmd-e] 'my/search-region)
  (define-key input-decode-map "\e[123;9z" [cmd-l])
  (global-set-key [cmd-l] 'select-current-word)
)

(defun my/search-region ()
  "Search forward for the current region or symbol at point."
  (interactive)
  (let* ((text (
    if (use-region-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
      (thing-at-point 'symbol t)
    )))
    (when text
      (deactivate-mark)
      (isearch-mode t)
      (isearch-yank-string text)
    )
  )
)

(defun custom-join-lines (arg)
  "My personal better join lines method"
  (interactive "p")
  (end-of-line)
  (delete-char 1)
  (delete-horizontal-space)
  )

(defun my/tsx-comment-style ()
  "Use line comments (//) in TSX and JSX regions."
  (when (derived-mode-p 'web-mode)
    ;; Use 'line' comments instead of block
    (setq-local comment-style 'indent)
    ;; Force comment string to //
    (setq-local comment-start "// ")
    (setq-local comment-end "")))

(defun my/delete-or-region ()
  "Delete selected region if active; otherwise delete the character at point."
  (interactive)
  (if (use-region-p)
      (delete-region (region-beginning) (region-end))
    (delete-char 1))
  )

(defun my/comment-or-region ()
  "Comment only the active region if one exists; otherwise comment the current line."
  (interactive)
  (if (use-region-p)
      ;; Comment or uncomment the active region only
      (comment-or-uncomment-region (region-beginning) (region-end))
    ;; Otherwise, fall back to commenting the current line
    (comment-line 1))
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

(defun custom-smart-yank ()
  "If region is active, replace it with the last yanked text.
Otherwise, just yank as usual."
  (interactive)
  (if (use-region-p)
      (progn
        (delete-region (region-beginning) (region-end))
        (yank))
    (yank))
  )

(defun custom-copy-line-or-region ()
  "If region is active, copy it. Otherwise, copy the current line."
  (interactive)
  (if (use-region-p)
      (kill-ring-save (region-beginning) (region-end))
    (kill-ring-save (line-beginning-position)
                    (line-beginning-position 2))
    (message "Line copied"))
  )

(defun custom-cut-line-or-region ()
  "If region is active, kill it. Otherwise, kill the current line."
  (interactive)
  (if (use-region-p)
      (kill-region (region-beginning) (region-end))
    (kill-whole-line))
  )

(defun my/kill-buffer-no-prompt-if-saved ()
  "Kill buffer without prompting if it is not modified."
  (interactive)
  (if (buffer-modified-p)
      (kill-buffer)
    (let ((kill-buffer-query-functions nil))
      (kill-buffer)))
  )

;; (defun my/tab-action ()
;;   "Try to expand a snippet. In Magit, toggle section.
;; If none found, insert a literal tab or indent as appropriate."
;;   (interactive)
;;   (cond
;;    ;; Case 1: Magit buffer
;;    ((derived-mode-p 'magit-mode)
;;     (let ((section (magit-current-section)))
;;       (when section
;;         (magit-section-toggle section))))

;;    ;; Case 2: snippet expansion succeeds
;;    ((yas-expand)
;;     t)

;;    ;; Case 3: normal indentation fallback
;;    (t
;;     (indent-for-tab-command)))
;;   )
(defun my/tab-action ()
  "Try to expand a snippet. If none found, do the right thing for the current mode."
  (interactive)
  (cond
   ;; If we're in Magit and at a section, toggle it.
   ((and (derived-mode-p 'magit-mode)
         (ignore-errors (magit-current-section)))
    (call-interactively #'magit-section-toggle))

   ;; Otherwise, try a yasnippet expansion.
   ((yas-expand)
    t)

   ;; Default fallback: indent or insert spaces.
   (t
    (indent-for-tab-command)))
)

(defun my/insert-console-log-util ()
  "Insert my console.log util snippet."
  (interactive)
  (yas-expand-snippet
   "console.log('$1:');\nconsole.log(require('util').inspect($1, false, null));")
  )

(defun duplicate-line ()
  "Duplicate the current line, or the active region if one is selected.
If a region is active, duplicates the selected text right after it.
If no region is active, duplicates the current line below it and keeps cursor column."
  (interactive)
  (if (use-region-p)
      ;; --- Duplicate the region ---
      (let* ((start (region-beginning))
             (end (region-end))
             (text (buffer-substring start end)))
        (goto-char end)
        (insert text))
    ;; --- Duplicate the current line ---
    (save-excursion
      (let ((col (current-column)))
        (move-beginning-of-line 1)
        (kill-line)
        (yank)
        (open-line 1)
        (forward-line 1)
        (yank)
        (move-to-column col))))
  )

(defun select-current-word (arg)
  "Select current word. If already a selection, match another word"

  (interactive "p")
  (when (use-region-p)
    (mc/mark-next-like-this (point))
    )
  (when (not (use-region-p))
    (left-word)
    (mark-word)
    )
  )

(defun move-line-up ()
  "Move up the current line."
  (interactive)
  (transpose-lines 1)
  (forward-line -2)
  (indent-according-to-mode)
  (deactivate-mark)
  )

(defun move-line-down ()
  "Move down the current line."
  (interactive)
  (forward-line 1)
  (transpose-lines 1)
  (forward-line -1)
  (indent-according-to-mode)
  )

(defun insert-line ()
  "Insert a new line below the current one and move point to it."
  (interactive)
  (end-of-line)
  (newline-and-indent)
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

(add-hook 'prog-mode-hook
          (lambda ()
            (local-set-key (kbd "M-q") #'delete-current-line))
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

(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "C-t") #'helm-projectile-find-file)
  )

;; Mike's customer stuff:
;; Make mouse wheel scroll normally
(global-set-key (kbd "<wheel-up>")   #'scroll-down-line)
(global-set-key (kbd "<wheel-down>") #'scroll-up-line)

;; Do not write anything past this comment. This is where Emacs will
;; auto-generate custom variable definitions.
(defun dotspacemacs/emacs-custom-settings ()
  "Emacs custom settings.
This is an auto-generated function, do not modify its content directly, use
Emacs customize menu instead.
This function is called at the very end of Spacemacs initialization."
  (custom-set-variables
   ;; custom-set-variables was added by Custom.
   ;; If you edit it by hand, you could mess it up, so be careful.
   ;; Your init file should contain only one such instance.
   ;; If there is more than one, they won't work right.
   '(custom-safe-themes
     '("d481904809c509641a1a1f1b1eb80b94c58c210145effc2631c1a7f2e4a2fdf4" default))
   '(package-selected-packages
     '(ace-link add-node-modules-path aggressive-indent all-the-icons auto-compile
                auto-highlight-symbol avy-jump-helm-line centered-cursor-mode
                clean-aindent-mode column-enforce-mode company define-word devdocs
                diminish dired-quick-sort disable-mouse dotenv-mode drag-stuff
                dumb-jump elisp-def elisp-demos elisp-slime-nav emmet-mode emr
                eval-sexp-fu evil-anzu evil-args evil-cleverparens evil-escape
                evil-evilified-state evil-exchange evil-goggles evil-iedit-state
                evil-indent-plus evil-lion evil-lisp-state evil-matchit evil-mc
                evil-nerd-commenter evil-numbers evil-surround evil-textobj-line
                evil-tutor evil-unimpaired evil-visual-mark-mode evil-visualstar
                ewal-doom-themes expand-region eyebrowse fancy-battery flycheck
                golden-ratio google-translate grizzl helm-ag helm-comint
                helm-descbinds helm-make helm-mode-manager helm-org
                helm-projectile helm-purpose helm-swoop helm-xref hide-comnt
                highlight-indentation highlight-numbers highlight-parentheses
                hl-todo holy-mode hungry-delete hybrid-mode import-js indent-guide
                info+ inspector js-doc js2-refactor json-mode json-navigator
                json-reformat link-hint livid-mode lorem-ipsum macrostep
                multi-line nameless nodejs-repl npm-mode open-junk-file
                org-superstar origami overseer page-break-lines paradox
                password-generator pcre2el popwin prettier-js quickrun
                rainbow-delimiters restart-emacs space-doc spaceline
                spacemacs-purpose-popwin spacemacs-whitespace-cleanup
                string-edit-at-point string-inflection symbol-overlay symon
                term-cursor toc-org treemacs-icons-dired treemacs-persp
                treemacs-projectile typescript-mode undo-fu undo-fu-session
                uuidgen vi-tilde-fringe volatile-highlights vundo web-beautify
                web-mode wgrep winum writeroom-mode ws-butler)))
  (custom-set-faces
   ;; custom-set-faces was added by Custom.
   ;; If you edit it by hand, you could mess it up, so be careful.
   ;; Your init file should contain only one such instance.
   ;; If there is more than one, they won't work right.
   )
  )
