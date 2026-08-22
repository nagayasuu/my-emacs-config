;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;;; Package management

;; Load Emacs' built-in package manager.
(require 'package)

;; Add MELPA after the existing package archives.
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/")
             t)

;; Add NonGNU Devel and pin gptel to that archive.
(add-to-list 'package-archives
             '("nongnu-devel" . "https://elpa.nongnu.org/nongnu-devel/"))
(add-to-list 'package-pinned-packages
             '(gptel . "nongnu-devel"))

;;; Personal paths

(defconst my-org-directory
  (expand-file-name "~/Dropbox/org/")
  "Root directory for Org files.")

;;; Platform integration

(when (eq system-type 'windows-nt)
  ;; Use UTF-8 as the default coding system on Windows.
  (set-language-environment "UTF-8")
  (prefer-coding-system 'utf-8-unix)
  (set-default-coding-systems 'utf-8-unix)
  (setq locale-coding-system 'utf-8)

  ;; Use Japanese names for weekdays and months.
  (setq system-time-locale "Japanese_Japan.65001")

  ;; Add MSYS2 tools to the executable search path.
  (let ((msys2-paths '("c:/msys64/ucrt64/bin"
                       "c:/msys64/usr/bin")))
    (dolist (dir (reverse msys2-paths))
      (add-to-list 'exec-path dir)
      (setenv "PATH"
              (concat dir path-separator (getenv "PATH")))))

  ;; Fix Japanese search terms passed to MSYS2 commands on Japanese Windows.
  (dolist (entry '(("[rR][gG]\\(?:\\.exe\\)?\\'"
                    . (utf-8-dos . cp932-dos))
                   ("[fF][iI][nN][dD]\\(?:\\.exe\\)?\\'"
                    . (utf-8-dos . cp932-dos))))
    (add-to-list 'process-coding-system-alist entry)))

;;; Core Emacs

;;;; Startup behavior

(setq inhibit-startup-screen t
      initial-major-mode 'org-mode
      initial-scratch-message nil
      frame-title-format '("%b")
      ring-bell-function #'ignore)

;;;; Appearance

;; Set the font for the initial frame.
;; (set-frame-font "UDEV Gothic JPDOC-15")
(set-frame-font "PlemolJP-13")

(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

(setq-default cursor-type 'bar)
(blink-cursor-mode 1)

;; Use the Ef Light theme.
;; (use-package ef-themes
;;   :ensure t
;;   :config
;;   (load-theme 'ef-light t))

(use-package catppuccin-theme
  :ensure t
  :no-require t
  :preface
  (defconst my-tab-line-vertical-padding 2
    "Vertical padding around tab-line labels, in pixels.")

  (defun my-catppuccin-tab-line-faces (theme)
    "Set contrasting tab-line faces when THEME is Catppuccin."
    (when (eq theme 'catppuccin)
      (custom-theme-set-faces
       'catppuccin
       `(tab-line-tab
         ((t (:inherit tab-line
              :foreground ,(catppuccin-color 'text)
              :box (:line-width (-1 . ,my-tab-line-vertical-padding)
                    :color ,(catppuccin-color 'base))))))
       `(tab-line-tab-current
         ((t (:inherit tab-line-tab))))
       `(tab-line-tab-inactive
         ((t (:foreground ,(catppuccin-color 'subtext0)
              :background ,(catppuccin-color 'surface0)
              :box (:line-width (-1 . ,my-tab-line-vertical-padding)
                    :color ,(catppuccin-color 'surface0)))))))
      (dolist (face '(tab-line-tab
                      tab-line-tab-current
                      tab-line-tab-inactive))
        (custom-theme-recalc-face face))))
  :init
  (setq catppuccin-flavor 'frappe)
  (add-hook 'enable-theme-functions #'my-catppuccin-tab-line-faces)
  :config
  (load-theme 'catppuccin :no-confirm))

;; Use a minimal mode line.
(use-package simple-modeline
  :ensure t
  :hook (after-init . simple-modeline-mode))

;;;; Tab line

(defun my-tab-line-tab-name-format (tab tabs)
  "Format TAB without changing its background on hover."
  (let* ((text (tab-line-tab-name-format-default tab tabs))
         (tab-face (get-text-property 0 'face text))
         (close-start 0))
    ;; The default formatter uses `tab-line-highlight' as the mouse face,
    ;; which replaces the tab's own background while the pointer is over it.
    (put-text-property 0 (length text) 'mouse-face tab-face text)
    (while (and (< close-start (length text))
                (not (equal (get-text-property close-start 'help-echo text)
                            "Close tab")))
      (setq close-start
            (next-single-property-change
             close-start 'help-echo text (length text))))
    (when (< close-start (length text))
      (add-text-properties
       close-start
       (next-single-property-change close-start 'help-echo text (length text))
       `(mouse-face ((:foreground "#e78284") ,tab-face))
       text))
    text))

(use-package tab-line
  :ensure nil
  :init
  (setq tab-line-new-button-show nil
        tab-line-separator ""
        tab-line-tab-name-function
        (lambda (buffer &optional _buffers)
          (concat " " (buffer-name buffer) " ")))
  (global-tab-line-mode 1)
  :config
  (setq tab-line-tab-name-format-function #'my-tab-line-tab-name-format
        tab-line-close-button
        (propertize "×"
                    'face '(:foreground "#888888" :height 1.0)
                    'keymap tab-line-tab-close-map
                    'mouse-face '(:inherit tab-line-highlight
                                  :foreground "#e78284")
                    'help-echo "Close tab"))
  (set-face-attribute 'tab-line-tab-special nil
                      :slant 'normal
                      :weight 'normal))

;; Add a thin spacer below the tab line.
;; (setq-default header-line-format " ")
;; (set-face-attribute 'header-line nil
;;                     :inherit 'default
;;                     :height 0.1
;;                     :box nil)

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

(savehist-mode 1)

(setq recentf-max-saved-items 200)
(recentf-mode 1)

(desktop-save-mode 1)

;;; Completion and navigation

;;;; Minibuffer completion

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

;; Provide enhanced navigation and selection commands.
(use-package consult
  :ensure t
  :preface
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

  :custom
  (consult-async-min-input 2)

  :bind
  (("<C-tab>" . consult-buffer)
   ("C-c f" . my-consult-find-select-directory)
   ("C-c r" . my-consult-ripgrep-select-directory)))

;;;; In-buffer completion

;; Keep the capitalization of dynamic abbreviations unchanged.
(setq dabbrev-case-replace nil)

;; Display completion-at-point candidates in a popup.
(use-package corfu
  :ensure t
  :init
  (global-corfu-mode)
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
  :init
  (which-key-mode 1))

;;; Org mode

;;;; Core

(use-package org
  :preface
  (defconst my-org-refile-excluded-directories
    '("archive/" "journal/")
    "Directories under `org-directory' excluded from refile targets.")

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

  :init
  (setq org-directory my-org-directory
        org-default-notes-file
        (expand-file-name "inbox.org" org-directory)
        org-capture-templates
        '(("t" "Task" entry
           (file+headline org-default-notes-file "Tasks")
           "* TODO %?\n"
           :empty-lines 1)
          ("n" "Note" entry
           (file+headline org-default-notes-file "Notes")
           "* %?\n"
           :empty-lines 1)))

  :custom
  ;; Workflow and storage.
  (org-log-done t)
  (org-element-use-cache nil)
  (org-agenda-files (list org-directory))
  (org-archive-location "archive/%s_archive::")

  ;; Refile to level 1 headings outside the excluded directories.
  (org-refile-targets '((my-org-refile-files :level . 1)))
  (org-refile-use-outline-path t)
  (org-outline-path-complete-in-steps nil)

  ;; Display descriptive links and hide emphasis markers such as *, /, =, and ~.
  (org-link-descriptive t)
  (org-hide-emphasis-markers t)

  :bind
  (("C-c l" . org-store-link)
   ("C-c a" . org-agenda)
   ("C-c c" . org-capture)
   :map org-mode-map
   ("C-c e" . org-emphasize))

  :hook
  ;; Visually indent content according to its heading level.
  (org-mode . org-indent-mode)

  :config
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((calc . t)))
  ;; Use 20 digits of internal precision for Calc source blocks.
  (with-eval-after-load 'calc
    (setq-default calc-internal-prec 20)))

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

;; Maintain date-based journal entries under the Org directory.
(use-package org-journal
  :ensure t
  :defer t
  :init
  (define-prefix-command 'my-org-journal-map)
  :custom
  (org-journal-dir (expand-file-name "journal/" org-directory))
  (org-journal-file-type 'weekly)
  (org-journal-file-format "%Y-%m-%d.org")
  (org-journal-date-format "%Y-%m-%d (%a)")
  (org-journal-time-format "")
  (org-journal-carryover-items "TODO=\"TODO\"")
  (org-journal-enable-agenda-integration t)
  (org-journal-file-header "#+startup: content\n")
  :bind
  (("C-c j" . my-org-journal-map)
   :map my-org-journal-map
   ("j" . org-journal-new-entry)
   ("o" . org-journal-open-current-journal-file)))

;;; AI assistance

;; Use an OAuth-authenticated OpenAI backend with gptel.
;; (use-package gptel
;;   :ensure t
;;   :config
;;   (setq gptel-model 'gpt-5.6-sol
;;         gptel-backend
;;         (gptel-make-openai-oauth "OpenAI-sub")))

;;; Customize

;; Keep settings written by Customize out of this file.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; Load Customize settings when the file exists.
(load custom-file 'noerror)

;;; init.el ends here
