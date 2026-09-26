;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;;; Commentary:

;; Personal Emacs configuration shared across supported platforms.
;; Feature-specific constants and helpers are kept beside the settings
;; that use them.

;;; Code:

;; Hide warnings about third-party Lisp files without a lexical-binding cookie.
(require 'warnings)
(add-to-list 'warning-suppress-log-types '(files missing-lexbind-cookie))

;;; Bootstrap

;;;; Customize storage

;; Choose the Customize output file before package setup can save settings.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;;;; Package management

;; Load Emacs' built-in package manager.
(require 'package)
(require 'use-package)

;; Provide Common Lisp forms used by personal Org commands.
(require 'cl-lib)

;; Add MELPA after the existing package archives.
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/")
             t)

;;; Shared paths

(defconst my-org-directory
  (if (eq system-type 'windows-nt)
      (expand-file-name "Dropbox/org/" (getenv "USERPROFILE"))
    (expand-file-name "~/Dropbox/org/"))
  "Root directory for Org files.")

;; `ccc' from ddskk uses color helpers provided by `facemenu'.
(with-eval-after-load 'ccc
  (require 'facemenu))

;;; Platform integration

;;;; Windows

(defconst my-windows-exec-paths
  '("c:/msys64/ucrt64/bin"
    "c:/msys64/usr/bin")
  "Directories prepended to the variable `exec-path' on Windows.")

(defun my-prepend-to-exec-path (directory)
  "Prepend DIRECTORY to variable `exec-path' and the PATH environment variable."
  (add-to-list 'exec-path directory)
  (let ((path-directories
         (delete directory
                 (split-string (or (getenv "PATH") "")
                               path-separator t))))
    (setenv "PATH"
            (mapconcat #'identity
                       (cons directory path-directories)
                       path-separator))))

(defun my-reveal-current-file-in-explorer ()
  "Open Windows Explorer with the current buffer's file selected."
  (interactive)
  (let ((file buffer-file-name))
    (unless file
      (user-error "Current buffer is not visiting a file"))
    (unless (eq system-type 'windows-nt)
      (user-error "Windows Explorer is only available on Windows"))
    (when (file-remote-p file)
      (user-error "Cannot select a remote file in Windows Explorer"))
    (w32-shell-execute
     "open" "explorer.exe"
     (format "/select,\"%s\""
             (subst-char-in-string ?/ ?\\ (expand-file-name file))))))

(when (eq system-type 'windows-nt)
  ;; Use UTF-8 as the default coding system on Windows.
  (set-language-environment "UTF-8")
  (prefer-coding-system 'utf-8-unix)
  (set-default-coding-systems 'utf-8-unix)
  (setq locale-coding-system 'utf-8)

  ;; Use Japanese names for weekdays and months.
  (setq system-time-locale "Japanese_Japan.65001")

  ;; Add MSYS2 tools to the executable search path, in the declared order.
  (dolist (directory (reverse my-windows-exec-paths))
    (my-prepend-to-exec-path directory))

  ;; Fix Japanese search terms passed to MSYS2 commands on Japanese Windows.
  (dolist (entry '(("[rR][gG]\\(?:\\.exe\\)?\\'"
                    . (utf-8-dos . cp932-dos))
                   ("[fF][iI][nN][dD]\\(?:\\.exe\\)?\\'"
                    . (utf-8-dos . cp932-dos))))
    (add-to-list 'process-coding-system-alist entry)))

;;; Core Emacs

;;;; Startup behavior

(setq inhibit-startup-screen t
      frame-title-format '("%b")
      ring-bell-function #'ignore)

;;;; Appearance

(defconst my-default-font-size
  (if (eq system-type 'gnu/linux) 13 11)
  "Default font size for the current operating system.")

(defconst my-default-font
  (format "PlemolJP-%d" my-default-font-size)
  "Font used in graphical frames.")

(defconst my-default-font-family
  "PlemolJP"
  "Font family used by text faces.")

(defconst my-variable-pitch-font-family
  "PlemolJP35"
  "Font family used by proportional text faces.")

(defun my-apply-default-font (&optional frame)
  "Apply the configured fonts to graphical FRAME."
  (with-selected-frame (or frame (selected-frame))
    (when (display-graphic-p)
      (set-frame-font my-default-font)
      ;; Doric uses these faces for code, tables, and proportional UI text.
      ;; `set-frame-font' only changes the `default' face.
      (set-face-attribute 'fixed-pitch nil :family my-default-font-family)
      (set-face-attribute 'variable-pitch nil
                          :family my-variable-pitch-font-family
                          :height 1.0))))

(defun my-apply-org-fixed-pitch-faces ()
  "Use the fixed-pitch family for Org code and metadata faces."
  (dolist (face '(org-block
                  org-block-begin-line
                  org-block-end-line
                  org-checkbox
                  org-code
                  org-column-title
                  org-date
                  org-document-info-keyword
                  org-drawer
                  org-formula
                  org-indent
                  org-meta-line
                  org-property-value
                  org-special-keyword
                  org-table
                  org-verbatim))
    (when (facep face)
      (set-face-attribute face nil :family my-default-font-family))))

;; Cover both a regular startup frame and frames created by the daemon.
(my-apply-default-font)
(add-hook 'after-make-frame-functions #'my-apply-default-font)

(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

(setq-default cursor-type 'bar)
(blink-cursor-mode 1)

(use-package doric-themes
  :ensure t
  :demand t
  :config
  (load-theme 'doric-mermaid :no-confirm)
  (my-apply-org-fixed-pitch-faces))

;; Use a minimal mode line.
(use-package simple-modeline
  :ensure t
  :hook (after-init . simple-modeline-mode))

;;;; Tab line

(defconst my-tab-line-close-hover-color "#e78284"
  "Foreground color of the tab-line close button on hover.")

(defconst my-tab-line-close-help-echo "Close tab"
  "Help text for the tab-line close button.")

(defun my-apply-tab-line-vertical-padding (&optional _theme)
  "Add vertical padding to tabs without drawing a hover border."
  (dolist (face '(tab-line-tab tab-line-tab-current tab-line-tab-inactive))
    (set-face-attribute face nil
                        :box '(:line-width (1 . 4) :style flat-button)))
  (set-face-attribute 'tab-line-highlight nil :box nil))

(defvar my-tab-line--hovered-close-button nil
  "Window and buffer whose tab close button is under the mouse.")

(defun my-tab-line--buffer (tab)
  "Return the buffer represented by TAB, a buffer or a tab alist."
  (if (bufferp tab) tab (cdr (assq 'buffer tab))))

(defun my-tab-line--modified-file-p (buffer)
  "Return non-nil when BUFFER visits a file and has unsaved changes."
  (and (buffer-live-p buffer)
       (buffer-file-name buffer)
       (buffer-modified-p buffer)))

(defun my-tab-line--close-button-help (window object position)
  "Return close-button help for OBJECT at POSITION in WINDOW."
  (let* ((tab (get-text-property position 'tab object))
         (buffer (my-tab-line--buffer tab)))
    (if (and (window-live-p window)
             (my-tab-line--modified-file-p buffer))
        (propertize my-tab-line-close-help-echo
                    'my-tab-line-close-hover (cons window buffer)
                    'help-echo-inhibit-substitution t)
      my-tab-line-close-help-echo)))

(defun my-tab-line--update-close-hover (help)
  "Update the hovered close button from mouse HELP, including exits."
  (let ((target (and (stringp help)
                     (> (length help) 0)
                     (get-text-property 0 'my-tab-line-close-hover help))))
    (unless (equal target my-tab-line--hovered-close-button)
      (setq my-tab-line--hovered-close-button target)
      (tab-line-force-update t))))

(defun my-tab-line--install-hover-handler ()
  "Track close-button hover through the current help display function."
  (when show-help-function
    (add-function :before show-help-function
                  #'my-tab-line--update-close-hover)))

(defun my-tab-line-tab-name (buffer &optional _buffers)
  "Return BUFFER's name with an icon and display padding."
  (let* ((file (buffer-file-name buffer))
         (icon (copy-sequence
                (if file
                    (nerd-icons-icon-for-file file)
                  (nerd-icons-codicon "nf-cod-file")))))
    (when icon
      ;; Save the icon face because the default tab formatter replaces it.
      (put-text-property 0 (length icon)
                         'my-tab-line-icon-face
                         (get-text-property 0 'face icon)
                         icon))
    (concat " " icon (and icon " ") (buffer-name buffer) " ")))

(defun my-tab-line--restore-icon-face (text)
  "Restore the Nerd Font face saved in tab-line TEXT."
  (when-let* ((icon-start
               (text-property-not-all 0 (length text)
                                      'my-tab-line-icon-face nil text))
              (icon-face
               (get-text-property icon-start
                                  'my-tab-line-icon-face text)))
    (let ((icon-end
           (next-single-property-change
            icon-start 'my-tab-line-icon-face text (length text))))
      (add-face-text-property icon-start icon-end icon-face nil text)
      (put-text-property icon-start icon-end 'mouse-face
                         (get-text-property icon-start 'face text)
                         text))))

(defun my-tab-line--highlight-close-button (text tab-face)
  "Highlight the close button in tab-line TEXT inheriting TAB-FACE."
  (let ((close-start 0))
    (while (and (< close-start (length text))
                (not (eq (get-text-property close-start 'help-echo text)
                         #'my-tab-line--close-button-help)))
      (setq close-start
            (next-single-property-change
             close-start 'help-echo text (length text))))
    (when (< close-start (length text))
      (add-text-properties
       close-start
       (next-single-property-change close-start 'help-echo text (length text))
       `(mouse-face ((:foreground ,my-tab-line-close-hover-color)
                     ,tab-face))
       text))))

(defvar tab-line-close-button)

(defun my-tab-line-tab-name-format (tab tabs)
  "Format TAB among TABS, indicating unsaved file changes."
  (let* ((buffer (my-tab-line--buffer tab))
         (tab-line-close-button
          (if (and (my-tab-line--modified-file-p buffer)
                   (not (and (eq (car-safe my-tab-line--hovered-close-button)
                                 (selected-window))
                             (eq (cdr-safe my-tab-line--hovered-close-button)
                                 buffer))))
              (let ((dot (copy-sequence "●")))
                (set-text-properties 0 1
                                     (text-properties-at 0 tab-line-close-button)
                                     dot)
                ;; Use the tab color instead of the close button's gray.
                (put-text-property 0 1 'face
                                   '(:inherit nil :height 0.8) dot)
                (concat dot (substring tab-line-close-button 1)))
            tab-line-close-button))
         (text (tab-line-tab-name-format-default tab tabs))
         (tab-face (get-text-property 0 'face text)))
    ;; The default formatter uses `tab-line-highlight' as the mouse face,
    ;; which replaces the tab's own background while the pointer is over it.
    (put-text-property 0 (length text) 'mouse-face tab-face text)
    ;; Restore the Nerd Font family and color while inheriting the tab face.
    (my-tab-line--restore-icon-face text)
    (my-tab-line--highlight-close-button text tab-face)
    text))

(use-package nerd-icons
  :ensure t)

(use-package tab-line
  :ensure nil
  :functions (tab-line-force-update
              tab-line-tab-name-format-default
              tab-line-tabs-fixed-window-buffers)
  :init
  (setq tab-line-tabs-function #'tab-line-tabs-fixed-window-buffers
        tab-line-new-button-show nil
        tab-line-close-modified-button-show nil
        tab-line-separator ""
        tab-line-tab-name-function #'my-tab-line-tab-name)
  (global-tab-line-mode 1)
  :config
  (setq tab-line-tab-name-format-function #'my-tab-line-tab-name-format
        tab-line-close-button
        (concat
         (propertize "×"
                     'face '(:foreground "#888888" :height 0.8)
                     'keymap tab-line-tab-close-map
                     'mouse-face `(:inherit tab-line-highlight
                                   :foreground ,my-tab-line-close-hover-color)
                     'help-echo #'my-tab-line--close-button-help)
         (propertize " " 'rear-nonsticky t)))
  (my-apply-tab-line-vertical-padding)
  (add-hook 'enable-theme-functions #'my-apply-tab-line-vertical-padding)
  (with-eval-after-load 'tooltip
    ;; Tooltip mode replaces `show-help-function' when toggled.
    (add-hook 'tooltip-mode-hook #'my-tab-line--install-hover-handler)
    (my-tab-line--install-hover-handler)))

;;;; Scrolling

(setq scroll-margin 0
      scroll-conservatively 100000
      scroll-preserve-screen-position t)

(pixel-scroll-precision-mode 1)

;;;; Editing behavior

(delete-selection-mode 1)
(electric-pair-mode 1)

(setq kill-whole-line t
      tab-always-indent 'complete)

;; Remove trailing whitespace whenever a buffer is saved.
(add-hook 'before-save-hook #'delete-trailing-whitespace)

;; Provide context-aware commands for copying and marking text.
(use-package easy-kill
  :ensure t
  :bind
  (([remap kill-ring-save] . easy-kill)
   ([remap mark-sexp] . easy-mark)))

;;;; Files and session persistence

;; Disabling auto-save also disables its crash-recovery data.
(setq make-backup-files nil
      auto-save-default nil)

(use-package savehist
  :ensure nil
  :init
  (savehist-mode 1))

(use-package recentf
  :ensure nil
  :init
  (recentf-mode 1)
  :custom
  (recentf-max-saved-items 200))

(defun my-desktop-save-tab-line-buffer-order ()
  "Store each window's tab-line buffer order as writable names."
  (walk-windows
   (lambda (window)
     (with-selected-window window
       (set-window-parameter
        window 'my-tab-line-buffer-order
        (mapcar #'buffer-name
                (tab-line-tabs-fixed-window-buffers)))))
   'no-minibuffer t))

(defun my-desktop-restore-tab-line-buffer-order ()
  "Restore each window's tab-line buffer order from saved names."
  (walk-windows
   (lambda (window)
     (when-let ((names (window-parameter
                        window 'my-tab-line-buffer-order)))
       (set-window-parameter
        window 'tab-line-buffers
        (delq nil (mapcar #'get-buffer names)))))
   'no-minibuffer t)
  (tab-line-force-update t))

(use-package desktop
  :ensure nil
  :init
  ;; Buffer objects are not writable in desktop files, so mirror their names
  ;; in a dedicated window parameter that frameset can serialize.
  (add-to-list 'window-persistent-parameters
               '(my-tab-line-buffer-order . writable))
  (add-hook 'desktop-save-hook #'my-desktop-save-tab-line-buffer-order)
  (add-hook 'desktop-after-read-hook
            #'my-desktop-restore-tab-line-buffer-order)
  (desktop-save-mode 1))

;;; Completion and navigation

;;;; Minibuffer completion

(defvar mini-frame-completions-frame)
(defvar mini-frame-frame)
(defvar pgtk-wait-for-event-timeout)

(defconst my-mini-frame--pgtk-hide-timeout 0.02
  "Maximum PGTK event wait when hiding a mini-frame child frame.")

(defun my-mini-frame--show-parameters ()
  "Return frame parameters for the minibuffer child frame."
  (append
   `((top . 10)
     (width . 0.7)
     (left . 0.5)
     (font . ,my-default-font))
   ;; Emacs 30 PGTK can lose keyboard focus after hiding a focused child.
   ;; Keep physical GTK focus in the parent; `mini-frame' redirects the
   ;; parent's input events to this child while its minibuffer is active.
   (when (eq (window-system (selected-frame)) 'pgtk)
     '((no-accept-focus . t)))))

(defun my-mini-frame--pgtk-child-frame-p (frame)
  "Return non-nil when FRAME is a live PGTK mini-frame child frame."
  (and (frame-live-p frame)
       (eq (window-system frame) 'pgtk)
       (or (eq frame mini-frame-frame)
           (eq frame mini-frame-completions-frame))))

(defun my-mini-frame--hide-pgtk-child-frame (hide &optional frame force)
  "Call HIDE for FRAME with optimized PGTK mini-frame cleanup.
FORCE is the optional second argument of `make-frame-invisible'."
  (let ((target (or frame (selected-frame))))
    (if (my-mini-frame--pgtk-child-frame-p target)
        (progn
          (when (eq target mini-frame-frame)
            (let ((parent (frame-parent target)))
              (when (frame-live-p parent)
                (redirect-frame-focus parent nil))))
          (when (frame-visible-p target)
            ;; PGTK's hide path waits for the entire timeout even if no map
            ;; event is pending.  Keep a short drain period for race safety.
            (let ((pgtk-wait-for-event-timeout
                   (if (floatp pgtk-wait-for-event-timeout)
                       (min pgtk-wait-for-event-timeout
                            my-mini-frame--pgtk-hide-timeout)
                     pgtk-wait-for-event-timeout)))
              (funcall hide target force))))
      (funcall hide frame force))))

;; Display the minibuffer in a child frame at the top of graphical frames.
;; `mini-frame' falls back to the regular minibuffer on terminal frames, so
;; keeping the mode enabled also supports GUI frames created by the daemon.
(use-package mini-frame
  :ensure t
  :custom
  (mini-frame-show-parameters #'my-mini-frame--show-parameters)
  ;; Vertico displays candidates inside the minibuffer, so a second child
  ;; frame for *Completions* only adds frame and focus management overhead.
  (mini-frame-handle-completions nil)
  ;; Keep the hidden child frame attached on PGTK/Wayland.  On Windows,
  ;; detaching lets `mini-frame' recover when a hidden frame still appears
  ;; visible to `frame-visible-p'.
  (mini-frame-detach-on-hide (eq system-type 'windows-nt))
  ;; Reuse the hidden child frame.  Deleting a focused PGTK child frame can
  ;; leave its parent without keyboard focus on Emacs 30.
  (mini-frame-delete-on-hide nil)
  (mini-frame-standalone nil)
  :config
  ;; Remove earlier focus-recovery workarounds when this file is reevaluated.
  (dolist (function '(my-mini-frame--restore-pgtk-parent-focus
                      my-mini-frame--focus-pgtk-parent-before-hide
                      my-mini-frame--clear-pgtk-focus-redirect
                      my-mini-frame--hide-pgtk-child-frame))
    (advice-remove 'make-frame-invisible function))
  (advice-add 'make-frame-invisible
              :around
              #'my-mini-frame--hide-pgtk-child-frame)

  (mini-frame-mode 1))

;; Display minibuffer completion candidates vertically.
(use-package vertico
  :ensure t
  :init
  (vertico-mode 1))

;; Match multiple input components in any order.
(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  ;; Use partial completion for file names and directory separators.
  (completion-category-overrides
   '((file (styles partial-completion)))))

;; Add contextual annotations to completion candidates.
(use-package marginalia
  :ensure t
  :init
  (marginalia-mode 1))

;;;; Navigation and search

(defun my-consult--select-directory (command)
  "Run COMMAND from `my-org-directory' and prompt for a directory."
  (let ((default-directory my-org-directory)
        (current-prefix-arg '(4)))
    (call-interactively command)))

(defun my-consult-ripgrep-select-directory ()
  "Run `consult-ripgrep' and prompt for the search directory."
  (interactive)
  (my-consult--select-directory #'consult-ripgrep))

(defun my-consult-find-select-directory ()
  "Run `consult-find' and prompt for the search directory."
  (interactive)
  (my-consult--select-directory #'consult-find))

(defun my-consult-org-agenda--annotate (cand)
  "Display Org TODO annotations at column 100 for agenda candidate CAND."
  (pcase-let ((`(,_level ,todo ,prio . ,_)
               (get-text-property 0 'consult-org--heading cand)))
    (concat
     #("   " 0 1 (display (space :align-to (+ left 100))))
     todo
     (and prio (format #(" [#%c]" 1 6 (face org-priority)) prio)))))

;; Provide enhanced navigation and selection commands.
(use-package consult
  :ensure t
  :functions (consult--customize-put
              consult-find
              consult-org-agenda
              consult-ripgrep)
  :custom
  (consult-async-min-input 2)

  :config
  (consult-customize
   consult-org-agenda
   :annotate #'my-consult-org-agenda--annotate)

  :bind
  (("<C-tab>" . consult-buffer)
   ("C-c f" . my-consult-find-select-directory)
   ("C-c g" . my-consult-ripgrep-select-directory)
   ("C-c h" . consult-org-agenda)))

;; Act on completion candidates and export search results to dedicated buffers.
(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)
   ("C-c E" . embark-export))
  :init
  (setq prefix-help-command #'embark-prefix-help-command))

;; Extend Embark's exports for Consult results, such as `consult-ripgrep'.
(use-package embark-consult
  :ensure t
  :after (embark consult)
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;;;; In-buffer completion

;; Keep the capitalization of dynamic abbreviations unchanged.
(use-package dabbrev
  :ensure nil
  :defer t
  :custom
  (dabbrev-case-replace nil))

;; Display completion-at-point candidates in a popup.
(use-package corfu
  :ensure t
  :init
  (global-corfu-mode 1)
  :custom
  ;; Start completion automatically after two characters and a short delay.
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  ;; Continue from the first candidate after reaching the last one.
  (corfu-cycle t))

;; Add additional completion-at-point backends.
(use-package cape
  :ensure t
  :init
  ;; Complete words found in the current and other relevant buffers.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  ;; Complete file-system paths.
  (add-hook 'completion-at-point-functions #'cape-file))

;;;; Command discovery

;; Display available key continuations after a prefix key is pressed.
(use-package which-key
  :ensure nil
  :init
  (which-key-mode 1))

;;; Org mode

;;;; Paths and refiling

(defvar org-directory)
(defvar org-refile-history)
(defvar org-refile-targets)
(defvar org-refile-use-outline-path)

(defconst my-org-refile-excluded-directories
  '("archive/" "journal/")
  "Directories under `org-directory' excluded from refile targets.")

(defvar my-org-refile--history-validation-pending nil
  "Non-nil while the next refile target table should validate history.")

(defun my-org-journal-directory ()
  "Return the journal directory under `org-directory'."
  (expand-file-name "journal/" org-directory))

(defun my-org-refile-files ()
  "Return agenda files that can be used as refile targets."
  (let ((excluded-directories
         (mapcar (lambda (directory)
                   (expand-file-name directory org-directory))
                 my-org-refile-excluded-directories)))
    (seq-remove
     (lambda (file)
       (seq-some
        (lambda (directory)
          (file-in-directory-p (expand-file-name file) directory))
        excluded-directories))
     (org-agenda-files))))

(defun my-org-latest-journal-file ()
  "Return the latest date-named journal file, or nil if none exists."
  (let ((journal-directory (my-org-journal-directory)))
    (when (file-directory-p journal-directory)
      (seq-find
       #'file-regular-p
       (sort (directory-files
              journal-directory t
              (rx string-start
                  (= 4 digit) "-" (= 2 digit) "-" (= 2 digit)
                  ".org" string-end))
             #'string>)))))

(defun my-org-refile-target-verify ()
  "Allow regular targets and the last heading in the latest journal file."
  (let ((latest-journal-file (my-org-latest-journal-file)))
    (or (not (and buffer-file-name
                  latest-journal-file
                  (file-equal-p buffer-file-name latest-journal-file)))
        (not (save-excursion
               (org-get-next-sibling))))))

(defun my-org-refile--ensure-valid-history (targets)
  "Keep `org-refile-history' aligned with the current TARGETS.
When no saved history entry is still a completion candidate, use
the first current target as the default.  Return TARGETS unchanged."
  (when my-org-refile--history-validation-pending
    (setq my-org-refile--history-validation-pending nil)
    (let* ((current-file
            (buffer-file-name (buffer-base-buffer (current-buffer))))
           (filename (and current-file (file-truename current-file)))
           (path-suffix (if org-refile-use-outline-path "/" ""))
           (target-names
            (mapcar
             (lambda (target)
               (if (and
                    (not (member org-refile-use-outline-path
                                 '(file full-file-path title)))
                    (not (equal filename
                                (file-truename (nth 1 target)))))
                   (concat (car target) path-suffix " ("
                           (file-name-nondirectory (nth 1 target)) ")")
                 (concat (car target) path-suffix)))
             targets))
           (valid-history
            (seq-filter (lambda (entry)
                          (member entry target-names))
                        org-refile-history)))
      (setq org-refile-history
            (or valid-history
                (and target-names (list (car target-names)))))))
  targets)

(defun my-org-refile--with-valid-history (function &rest arguments)
  "Call FUNCTION with ARGUMENTS while arranging to validate refile history."
  (let ((my-org-refile--history-validation-pending t))
    (apply function arguments)))

;;;; Capture and archiving

(defun my-org-capture-entry-template (heading)
  "Return a capture template for HEADING with standard entry metadata."
  (concat "* " heading "\n"
          ":PROPERTIES:\n"
          ":ID: %(org-id-new)\n"
          ":CREATED_AT: %U\n"
          ":UPDATED_AT: %U\n"
          ":END:\n"))

(defun my-org-capture-project-heading ()
  "Move point to a selected top-level project heading."
  (let ((org-refile-targets '((nil :level . 1)))
        ;; Do not change the history used by regular refile commands.
        (org-refile-history nil)
        ;; Top-level targets do not need outline-path completion.
        (org-refile-use-outline-path nil))
    (goto-char
     (nth 3
          (org-refile-get-location "Project" (current-buffer))))))

(defun my-org-capture-fold-properties ()
  "Fold property drawers after `org-capture'."
  (when (derived-mode-p 'org-mode)
    (org-fold-hide-drawer-all)))

;;;; Entry modification timestamps

(defvar-local my-org-updated-at--changed-headings nil
  "Markers for edited headings and their ancestors since the last save.")

(defvar-local my-org-updated-at--updating nil
  "Non-nil while updating entry timestamps before saving.")

(defun my-org-updated-at--remember-heading ()
  "Remember the heading at point for the next save."
  (let ((position (line-beginning-position)))
    (unless (cl-some (lambda (entry)
                       (= position (marker-position (car entry))))
                     my-org-updated-at--changed-headings)
      (push (cons (copy-marker position t)
                  (org-entry-get nil "ID"))
            my-org-updated-at--changed-headings))))

(defun my-org-updated-at--remember-subtree ()
  "Remember the heading at point and its ancestors for the next save."
  (save-excursion
    (my-org-updated-at--remember-heading)
    (while (org-up-heading-safe)
      (my-org-updated-at--remember-heading))))

(defun my-org-updated-at--track-change (begin end _old-length)
  "Remember headings containing a change from BEGIN to END."
  (unless my-org-updated-at--updating
    (save-excursion
      (save-match-data
        (goto-char begin)
        (unless (org-before-first-heading-p)
          (org-back-to-heading t)
          (my-org-updated-at--remember-subtree))
        (goto-char begin)
        (while (re-search-forward org-heading-regexp end t)
          (org-back-to-heading t)
          (my-org-updated-at--remember-subtree)
          (end-of-line))))))

(defun my-org-updated-at--before-save ()
  "Set `UPDATED_AT' on edited entries and their ancestors."
  (let ((entries my-org-updated-at--changed-headings)
        (timestamp (format-time-string (org-time-stamp-format t t)))
        (my-org-updated-at--updating t))
    (setq my-org-updated-at--changed-headings nil)
    (save-excursion
      (dolist (entry entries)
        (let ((marker (car entry))
              (id (cdr entry)))
          (when (marker-buffer marker)
            (goto-char marker)
            (when (and (org-at-heading-p)
                       (or (null id) (equal id (org-entry-get nil "ID")))
                       (not (equal timestamp
                                   (org-entry-get nil "UPDATED_AT"))))
              (org-entry-put nil "UPDATED_AT" timestamp)))
          (set-marker marker nil))))))

(defun my-org-updated-at--setup ()
  "Track modified Org entries in the current buffer."
  (add-hook 'after-change-functions #'my-org-updated-at--track-change nil t)
  (add-hook 'before-save-hook #'my-org-updated-at--before-save nil t))

(defun my-org-archive-subtrees-without-open-todo ()
  "Archive direct child subtrees with no open TODO items without prompting."
  (interactive)
  (unless (org-at-heading-p)
    (user-error "Point must be on an Org heading"))
  (require 'org-archive)
  (cl-letf (((symbol-function 'y-or-n-p) (lambda (&rest _) t)))
    (org-archive-all-done)))

;;;; Plain-list folding

(defvar org-cycle-subtree-status)

(defun my-org-list-item-fold-end (item struct)
  "Return ITEM's fold end in STRUCT while preserving its final newline."
  (let ((end (org-list-get-item-end item struct)))
    (if (and (> end (point-min))
             (eq (char-before end) ?\n))
        (1- end)
      end)))

(defun my-org-list-set-item-visibility-through-blank-lines
    (function item struct view)
  "Call FUNCTION for ITEM in STRUCT and include blank lines in VIEW."
  (cl-letf (((symbol-function 'org-list-get-item-end-before-blank)
             #'my-org-list-item-fold-end))
    (funcall function item struct view)))

(defun my-org-show-inserted-list-item (inserted)
  "Show a newly INSERTED list item and return INSERTED unchanged."
  (when (and inserted (org-at-item-p))
    (save-excursion
      (beginning-of-line)
      (let ((item (point)))
        (org-list-set-item-visibility
         item (org-list-struct) 'subtree))))
  inserted)

(defun my-org-cycle-list-item-through-blank-lines (arg)
  "Cycle an Org list item while including its trailing blank lines.
When an item has text separated from its bullet by blank lines, include
that text as well.  An item with only a separator before the next item
folds that separator directly.  With prefix ARG, use regular Org cycling."
  (interactive "P")
  (if (and (not arg) (org-at-item-p))
      (save-excursion
        (beginning-of-line)
        (let* ((item (point))
               (struct (org-list-struct))
               (line-end (line-end-position))
               (content-end
                (org-list-get-item-end-before-blank item struct))
               (item-end (org-list-get-item-end item struct))
               (fold-end (my-org-list-item-fold-end item struct)))
          (if (and (= content-end line-end)
                   ;; Require an actual blank line, not merely the
                   ;; terminating newline of the item.
                   (> item-end (1+ line-end)))
              ;; The item contains only trailing blank lines.
              (let ((folded (org-fold-folded-p line-end 'outline)))
                (org-fold-region line-end fold-end (not folded) 'outline)
                (setq org-cycle-subtree-status
                      (if folded 'subtree 'folded))
                (org-unlogged-message
                 (if folded "SUBTREE" "FOLDED")))
            ;; Include blank lines occurring inside or after the item.
            (cl-letf (((symbol-function
                        'org-list-get-item-end-before-blank)
                       #'my-org-list-item-fold-end))
              (org-cycle arg)))))
    (org-cycle arg)))

(defun my-org-sort-keep-folds (function &rest args)
  "Preserve outline folds while calling sorting FUNCTION with ARGS."
  (let ((tag (make-symbol "org-sort-fold")))
    (unwind-protect
        (progn
          ;; Text properties move with entries when `sort-subr' rearranges them.
          (with-silent-modifications
            (save-restriction
              (widen)
              (dolist (fold (org-fold-get-regions :specs 'outline))
                (put-text-property
                 (car fold) (1+ (car fold)) tag
                 (- (cadr fold) (car fold))))))
          (apply function args))
      (save-excursion
        (save-restriction
          (widen)
          (goto-char (point-min))
          (while (< (point) (point-max))
            (let ((length (get-text-property (point) tag)))
              (when length
                (org-fold-region (point) (+ (point) length) t 'outline)))
            (goto-char
             (or (next-single-property-change
                  (point) tag nil (point-max))
                 (point-max))))
          (with-silent-modifications
            (remove-text-properties
             (point-min) (point-max) (list tag nil))))))))

;;;; Core configuration

(use-package org
  :ensure nil
  :defines org-capture-templates
  :functions (org-agenda-files
              org-agenda-list
              org-archive-all-done
              org-at-heading-p
              org-at-item-p
              org-fold-folded-p
              org-fold-get-regions
              org-fold-hide-drawer-all
              org-fold-region
              org-get-next-sibling
              org-id-new
              org-list-get-item-end
              org-list-get-item-end-before-blank
              org-list-set-item-visibility
              org-list-struct
              org-refile-get-location
              org-refile-get-targets
              org-unlogged-message)
  :init
  (setq org-directory my-org-directory
        org-default-notes-file
        (expand-file-name "inbox.org" org-directory)
        org-capture-templates
        `(("t" "Task" entry
           (file+headline org-default-notes-file "Tasks")
           ,(my-org-capture-entry-template "TODO %?")
           :empty-lines 1)
          ("p" "Project task" entry
           (file+function "projects.org" my-org-capture-project-heading)
           ,(my-org-capture-entry-template "TODO %?")
           :empty-lines 1)
          ("P" "Project note" entry
           (file+function "projects.org" my-org-capture-project-heading)
           ,(my-org-capture-entry-template "%?")
           :empty-lines 1)
          ("n" "Note" entry
           (file+headline org-default-notes-file "Notes")
           ,(my-org-capture-entry-template "%?")
           :empty-lines 1)))

  :custom
  ;; Workflow and storage.
  (org-todo-keywords
   '((sequence
      "TODO(t)"
      "INPROGRESS(i)"
      "WAITING(w@)"
      "|"
      "DONE(d)"
      "CANCELED(c@)")))
  (org-log-done t)
  (org-log-into-drawer t)
  (org-element-use-cache nil)
  ;; Keep property values separated by a single space instead of aligning
  ;; them to a fixed property-name width.
  (org-property-format "%s %s")
  (org-agenda-files (list my-org-directory))
  ;; Display agenda views in the selected window instead of splitting it.
  (org-agenda-window-setup 'current-window)
  (org-archive-location "archive/%s_archive::")

  ;; Refile to level 1 headings in regular files and the latest journal heading.
  (org-refile-targets '((my-org-refile-files :level . 1)
                        (my-org-latest-journal-file :level . 1)))
  (org-refile-target-verify-function #'my-org-refile-target-verify)
  (org-refile-use-outline-path t)
  (org-outline-path-complete-in-steps nil)

  ;; Hide emphasis markers such as *, /, =, and ~.
  (org-hide-emphasis-markers t)

  ;; Include plain lists in subtree visibility cycling.
  (org-cycle-include-plain-lists 'integrate)

  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . org-capture)
   ("C-c l" . org-store-link)
   :map org-mode-map
   ("C-c A" . my-org-archive-subtrees-without-open-todo)
   ("C-c e" . org-emphasize)
   ([remap org-cycle] . my-org-cycle-list-item-through-blank-lines))

  :hook
  ;; Render regular Org prose with the `variable-pitch' face.
  (org-mode . variable-pitch-mode)
  ;; Visually indent content according to its heading level.
  (org-mode . org-indent-mode)
  ;; Refresh timestamps for edited entries and their containing headings.
  (org-mode . my-org-updated-at--setup)

  :config
  ;; Keep planning and property metadata in the fixed-pitch family.
  (my-apply-org-fixed-pitch-faces)

  ;; Reinstall local hooks when this init file is reloaded with Org buffers open.
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when (derived-mode-p 'org-mode)
        (my-org-updated-at--setup))))

  ;; Fold property drawers in the newly captured entry.
  (add-hook 'org-capture-mode-hook #'my-org-capture-fold-properties)

  ;; Keep existing headline folds when sorting moves entries.
  (unless (advice-member-p #'my-org-sort-keep-folds 'org-sort-entries)
    (advice-add 'org-sort-entries :around #'my-org-sort-keep-folds))

  ;; Use the same blank-line folding boundary when Org folds list items
  ;; indirectly while cycling a containing heading.
  (with-eval-after-load 'org-list
    (advice-add
     'org-list-set-item-visibility
     :around
     #'my-org-list-set-item-visibility-through-blank-lines)
    ;; `org-list-write-struct' can copy an existing fold to a list item
    ;; inserted with `M-RET'; reveal only that newly inserted item.
    (advice-add 'org-insert-item
                :filter-return
                #'my-org-show-inserted-list-item))

  ;; Prevent saved refile history from becoming a stale default when the
  ;; available journal target changes.
  (with-eval-after-load 'org-refile
    (advice-add 'org-refile-get-location
                :around
                #'my-org-refile--with-valid-history)
    (advice-add 'org-refile-get-targets
                :filter-return
                #'my-org-refile--ensure-valid-history))

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((calc . t)))
  ;; Use 20 digits of internal precision for Calc source blocks.
  (with-eval-after-load 'calc
    (setq-default calc-internal-prec 20)))

;;;; Links

;; Configure how Org links are displayed and followed.
(use-package ol
  :ensure nil
  :after org
  :defines org-link-frame-setup
  :custom
  (org-link-descriptive t)
  :config
  ;; Open file links in the current window when following them with `C-c C-o'.
  (setf (alist-get 'file org-link-frame-setup) #'find-file))

;; Store links to Org entries using stable IDs, creating IDs as needed.
(use-package org-id
  :ensure nil
  :after org
  :functions org-id-get-create
  :custom
  (org-id-link-to-org-use-id t))

;;;; Display

;; Reveal hidden Org markup around the element at point.
(use-package org-appear
  :ensure t
  :after org
  :custom
  ;; Reveal emphasis markers.
  (org-appear-autoemphasis t)
  ;; Reveal complete link syntax.
  (org-appear-autolinks t)
  ;; Reveal Org entity source text.
  (org-appear-autoentities t)
  :hook (org-mode . org-appear-mode))

;;;; Journal

(defun my-org-journal-add-entry-id ()
  "Add metadata to the newly created journal entry."
  (org-id-get-create)
  (org-entry-put
   (point)
   "CREATED_AT"
   (format-time-string (org-time-stamp-format t t))))

(defun my-org-journal-new-entry-on-startup ()
  "Create today's date heading and carry over TODO items if it is absent."
  (require 'org-journal)
  (unless (member (calendar-current-date)
                  (org-journal--list-dates))
    (org-journal-new-entry t)))

(defun my-org-journal--at-heading-p ()
  "Return non-nil when point is within an Org journal entry."
  (and (derived-mode-p 'org-mode)
       (org-journal-is-journal)
       (not (org-before-first-heading-p))))

(defun my-org-journal-fold-current-file (&rest _)
  "Fold older dates and show current date headings without their bodies."
  (when (my-org-journal--at-heading-p)
    (save-excursion
      (save-restriction
        (widen)
        (org-back-to-heading t)
        (while (org-up-heading-safe))
        (org-overview)
        (org-narrow-to-subtree)
        (org-content)))))

(defun my-org-journal-fold-current-file-and-show-entry (prefix &rest _)
  "Fold older journal dates while leaving the new entry unfolded.
When PREFIX is non-nil, keep the current date folded because no entry
is created."
  (my-org-journal-fold-current-file)
  (when (and (not prefix)
             (my-org-journal--at-heading-p))
    (org-fold-show-entry)))

(defun my-org-journal-pcomplete-find-completion-function (orig command)
  "Use Org's pcomplete functions in `org-journal-mode'."
  (or (funcall orig command)
      (and (derived-mode-p 'org-journal-mode)
           (let ((major-mode 'org-mode))
             (funcall orig command)))))

(define-prefix-command 'my-org-journal-map)

;; Maintain date-based journal entries under the Org directory.
(use-package org-journal
  :ensure t
  :defer t
  :defines my-org-journal-map
  :functions (calendar-current-date
              org-back-to-heading
              org-before-first-heading-p
              org-content
              org-entry-put
              org-fold-show-entry
              org-journal--list-dates
              org-journal-is-journal
              org-narrow-to-subtree
              org-overview
              org-time-stamp-format
              org-up-heading-safe)
  :init
  (add-hook 'emacs-startup-hook
            #'my-org-journal-new-entry-on-startup)
  :custom
  (org-journal-dir (my-org-journal-directory))
  (org-journal-file-type 'weekly)
  (org-journal-file-format "%Y-%m-%d.org")
  (org-journal-date-format "%Y-%m-%d (%a)")
  (org-journal-time-format "")
  (org-journal-carryover-items "/!")
  (org-journal-enable-agenda-integration t)
  (org-journal-file-header "#+startup: content\n\n\n")
  (org-journal-find-file-fn #'find-file)
  :hook
  (org-journal-after-entry-create . my-org-journal-add-entry-id)
  :bind
  (("C-c j" . my-org-journal-map)
   :map my-org-journal-map
   ("j" . org-journal-new-entry)
   ("o" . org-journal-open-current-journal-file))
  :config
  ;; Replace the former shared advice when this configuration is reloaded.
  (advice-remove 'org-journal-new-entry
                 #'my-org-journal-fold-current-file)

  ;; `pcomplete' looks up functions by the exact major mode name.  Fall back
  ;; to Org's functions so their keyword completion also works in journals.
  (advice-remove
   'pcomplete-find-completion-function
   #'my-org-journal-pcomplete-find-completion-function)
  (advice-add
   'pcomplete-find-completion-function
   :around
   #'my-org-journal-pcomplete-find-completion-function)

  ;; Fold older dates after opening, but leave a newly created entry unfolded.
  (advice-add 'org-journal-new-entry
              :after
              #'my-org-journal-fold-current-file-and-show-entry)
  (advice-add 'org-journal-open-current-journal-file
              :after
              #'my-org-journal-fold-current-file))

;;;; Startup agenda

(defun my-org-agenda-show-today-on-startup ()
  "Show today's Org agenda in the most recently used ordinary window."
  (when-let ((target-window
              (get-mru-window (selected-frame) nil nil t)))
    (select-window target-window))
  (org-agenda-list nil nil 'day))

;; Run after the startup journal hook so the agenda remains visible.
(add-hook 'emacs-startup-hook
          #'my-org-agenda-show-today-on-startup
          t)

;;; Customize

;; Apply settings written by Customize after the declarative settings above.
(load custom-file 'noerror)

;;; init.el ends here
