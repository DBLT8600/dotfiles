(when (display-graphic-p)
  (require 'server)
  (unless (server-running-p)
    (server-start))

  (setq confirm-kill-emacs 'yes-or-no-p)

  (custom-set-faces
   '(default ((t (:foundry "0xProto" :family "0xProto")))))

  (set-fontset-font
   t
   'japanese-jisx0208
   (font-spec :family "Noto Sans CJK JP"))

  (set-language-environment "Japanese")
  )

(add-hook
 'after-save-hook
 (lambda ()
   (let ((file-name (buffer-file-name (current-buffer))))
     (when (and (file-exists-p file-name)
                (eq (point-min) (point-max)))
       (delete-file file-name)))))

(add-hook
 'after-save-hook
 'executable-make-buffer-file-executable-if-script-p)

(add-hook
 'kill-emacs-hook
 (lambda ()
   (when (and
          (boundp 'custom-file)
          (file-exists-p custom-file))
     (delete-file custom-file))))

(defvar scratch-buffer-file
  (locate-user-emacs-file "scratch"))

(add-hook
 'after-init-hook
 (lambda ()
   (when (file-exists-p scratch-buffer-file)
     (with-current-buffer (get-buffer-create "*scratch*")
       (erase-buffer)
       (insert-file-contents scratch-buffer-file)))))

(add-hook
 'kill-emacs-hook
 (lambda ()
   (with-current-buffer (get-buffer-create "*scratch*")
     (write-region (point-min) (point-max) scratch-buffer-file nil t))))

(add-hook
 'buffer-kill-hook
 (lambda ()
   (when (eq (current-buffer) (get-buffer "*scratch*"))
     (rename-buffer "*scratch~*")
     (clone-buffer "*scratch*"))))

(custom-set-variables
 '(custom-file (locate-user-emacs-file (format "emacs-%d.el" (emacs-pid))))
 '(default-directory "~/")
 '(exec-path
   `(,(expand-file-name "~/bin")
     ,(expand-file-name "~/.local/share/mise/shims")
     "/opt/homebrew/bin"
     "/usr/local/bin"
     "/usr/bin"
     "/bin"
     "/usr/sbin"
     "/sbin"))
 '(find-file-visit-truename t)
 '(global-auto-revert-mode t)
 '(indent-tabs-mode nil)
 '(inhibit-startup-screen t)
 '(initial-scratch-message nil)
 '(make-backup-files nil)
 '(pop-up-windows nil)
 '(require-final-newline 'visit-save)
 '(scroll-bar-mode nil)
 '(scroll-step 1)
 '(set-file-name-coding-system 'utf-8)
 '(set-keyboard-coding-system 'utf-8)
 '(set-mark-command-repeat-pop t)
 '(set-terminal-coding-system 'utf-8)
 '(show-paren-mode t)
 '(split-width-threshold 0)
 '(system-time-locale "C" t))

(load-theme 'anticolor t)

(let ((display-table (or buffer-display-table standard-display-table)))
  (when display-table
    ;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Display-Tables.html
    (set-display-table-slot display-table 1 ? )
    (set-display-table-slot display-table 5 ?│)
    (set-window-display-table (selected-window) display-table)))

(add-to-list
 'package-archives
 '("melpa" . "https://melpa.org/packages/") t)

(use-package org-mode
  :commands org-agenda
  :mode ("\\.org\\'" . org-mode)
  :init
  (setq org-directory (expand-file-name "~/org/"))
  (setq org-default-notes-file (concat org-directory "notes.org"))
  (setq org-agenda-files (list org-directory))
  :config
  (let ((org-global (concat org-directory "org-global.el")))
    (when file-exist-p org-global
	  (load org-global)))
  :bind
  (("C-c a" . org-agenda)
   ("C-c c" . org-capture)
   ("C-c g" . org-clock-goto)
   ("C-c n" . (lambda () (interactive) (find-file org-default-notes-file)))
   :map org-mode-map
   ("C-m" . org-return-indent)
   ("M-n" . org-forward-same-level)
   ("M-p" . org-backward-same-level))
  )

(use-package popwin
  :ensure t
  :init
  (push "*Warnings*" popwin:special-display-config)
  (push "*Backtrace*" popwin:special-display-config))
