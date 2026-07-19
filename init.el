;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

;;; Package management

;; Load Emacs' built-in package manager.
(require 'package)

;; Add MELPA Stable after the existing package archives.
(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/")
             t)

;;; Platform integration

(when (eq system-type 'windows-nt)
  ;; Use UTF-8 as the default coding system on Windows.
  (set-language-environment "UTF-8")
  (prefer-coding-system 'utf-8-unix)
  (set-default-coding-systems 'utf-8-unix)
  (setq locale-coding-system 'utf-8)

  ;; Add MSYS2 UCRT64 tools to the executable search path.
  (let ((msys2-bin "c:/msys64/ucrt64/bin"))
    (add-to-list 'exec-path msys2-bin)
    (setenv "PATH"
            (concat msys2-bin path-separator (getenv "PATH"))))

  ;; Fix Japanese search terms passed to ripgrep on Japanese Windows.
  (add-to-list
   'process-coding-system-alist
   '("[rR][gG]\\(?:\\.exe\\)?\\'"
     . (utf-8-dos . cp932-dos))))

;;; Startup behavior

;; Skip the startup screen.
(setq inhibit-startup-screen t)

;; Open the *scratch* buffer in Org mode without an initial message.
(setq initial-major-mode 'org-mode
      initial-scratch-message nil)

;; Display only the current buffer name in the frame title.
(setq frame-title-format '("%b"))

;;; Appearance

;; Set the font for the initial frame.
(set-frame-font "PlemolJP-10")

;; Hide interface elements for a cleaner layout.
(menu-bar-mode -1)
(scroll-bar-mode -1)
(tool-bar-mode -1)

;; Use a blinking bar cursor.
(setq-default cursor-type 'bar)
(blink-cursor-mode 1)

;; Install and load the Ef Light theme.
(use-package ef-themes
  :ensure t
  :config
  (load-theme 'ef-light t))

;; Enable a minimal mode line after Emacs finishes starting.
(use-package simple-modeline
  :ensure t
  :hook (after-init . simple-modeline-mode))

;;; Editing behavior

;; Replace the active region when text is inserted.
(delete-selection-mode 1)

;; Automatically insert matching delimiters.
(electric-pair-mode 1)

;; Kill the newline when killing a complete line with C-k.
(setq kill-whole-line t)

;; Indent with TAB when possible; otherwise invoke completion.
(setq tab-always-indent 'complete)

;; Remove trailing whitespace whenever a buffer is saved.
(add-hook 'before-save-hook #'delete-trailing-whitespace)

;; Uncomment the following line to display trailing whitespace.
;; (setq-default show-trailing-whitespace t)

;; Disable backup and auto-save files.
;; Disabling auto-save also disables crash recovery through auto-save data.
(setq make-backup-files nil
      auto-save-default nil)

;;; History and session persistence

;; Preserve minibuffer history between Emacs sessions.
(savehist-mode 1)

;; Track up to 200 recently opened files.
(setq recentf-max-saved-items 200)
(recentf-mode 1)

;; Restore buffers and the window layout from the previous session.
(desktop-save-mode 1)

;;; Minibuffer completion

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

(defun my-consult-ripgrep-select-directory ()
  "Run `consult-ripgrep' and prompt for the search directory."
  (interactive)
  (let ((current-prefix-arg '(4)))
    (call-interactively #'consult-ripgrep)))

;; Provide enhanced navigation and selection commands.
(use-package consult
  :ensure t
  :bind
  (("<C-tab>" . consult-buffer)
   ("C-c r" . my-consult-ripgrep-select-directory)))

;;; In-buffer completion

;; Display completion-at-point candidates in a popup.
(use-package corfu
  :ensure t
  :custom
  ;; Start completion automatically after two characters and a short delay.
  (corfu-auto t)
  (corfu-auto-delay 0.2)
  (corfu-auto-prefix 2)
  ;; Continue from the first candidate after reaching the last one.
  (corfu-cycle t)
  :init
  (global-corfu-mode))

;; Add additional completion-at-point backends.
(use-package cape
  :ensure t
  :init
  ;; Complete words found in the current and other relevant buffers.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  ;; Complete file-system paths.
  (add-hook 'completion-at-point-functions #'cape-file))

;;; Command discovery

;; Display available key continuations after a prefix key is pressed.
(use-package which-key
  :init
  (which-key-mode 1))

;;; Org mode

(use-package org
  :bind
  (:map org-mode-map
        ("C-c e" . org-emphasize))
  :custom
  ;; Record a timestamp when a TODO item is marked as DONE.
  (org-log-done t)
  ;; Hide emphasis markers such as *, /, =, and ~.
  (org-hide-emphasis-markers t)
  ;; Display descriptive links instead of complete link syntax.
  (org-link-descriptive t)
  ;; Display Org entities such as \alpha as symbols.
  ;; (org-pretty-entities t)
  :hook
  ;; Visually indent content according to its heading level.
  (org-mode . org-indent-mode))

;; Reveal hidden Org markup around the element at point.
(use-package org-appear
  :ensure t
  :after org
  :hook (org-mode . org-appear-mode)
  :custom
  ;; Reveal emphasis markers.
  (org-appear-autoemphasis t)
  ;; Reveal complete link syntax.
  (org-appear-autolinks t)
  ;; Reveal subscript and superscript markers.
  ;; (org-appear-autosubmarkers t)
  ;; Reveal Org entity source text.
  (org-appear-autoentities t))


;;; init.el ends here
