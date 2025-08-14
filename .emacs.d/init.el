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

(eval-and-compile
  (customize-set-variable
   'package-archives
   '(("gnu" . "https://elpa.gnu.org/packages/")
     ("melpa" . "https://melpa.org/packages/")
     ("nongnu" . "https://elpa.nongnu.org/nongnu/")))

  (package-initialize)

  (unless (package-installed-p 'leaf)
    (package-install 'leaf))

  (leaf leaf-keywords
    :ensure t
    :config
    (leaf hydra :ensure t)
    (leaf el-get :ensure t)
    (leaf blackout :ensure t)
    ;; (leaf-keywords-init)))
    ))

(leaf eshell
  :bind ("C-#" . eshell)
  :custom (eshell-path-env . `,(string-join exec-path ":"))
  :config
  (defun eshell/hello ()
    (message "hello world")))

(leaf gnus
  :custom
  (gnus-home-directory . "~/gnus")
  (message-directory . `,(concat gnus-home-directory "/Mail"))
  (mail-source-directory . message-directory)
  (nnfolder-directory . `,(concat message-directory "/archive"))
  (pop3-uidl-file . `,(concat gnus-home-directory "/.pop3-uidl"))
  (nntmp-authinfo-file . `,(concat gnus-home-directory "/.authinfo"))
  (auth-sources . `(nntmp-authinfo-file
                    ,(concat gnus-home-directory "/.authinfo.gpg")
                    ,(concat gnus-home-directory "/.netrc"))))

(leaf ido
  :custom
  (ido-enable-flex-matching . t)
  (ido-use-faces . t)
  :config
  (leaf imenu-anywhere :ensure t :bind ("M-." . ido-imenu-anywhere))
  (leaf smex :ensure t :bind (("M-x" . smex) ("M-X" . smex-major-mode-commands)))
  (leaf ido-vertical-mode
    :ensure t
    :custom (ido-vertical-define-keys . 'C-n-and-C-p-only)
    :global-minor-mode ido-vertical-mode)
  (leaf ido-completing-read+ :ensure t :global-minor-mode ido-ubiquitous-mode)
  (ido-mode t)
  (ido-everywhere t))

(leaf js-mode
  :hook (js-mode-hook . (lambda ()
                          (make-local-variable 'js-indent-level)
                          (setq js-indent-level 2))))

(leaf org-mode
  :init
  (defvar www-get-page-title-user-agent
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36")

  (defun www-get-page-title (url)
    (let ((url-request-method "GET")
          (url-automatic-caching t)
          (url-request-extra-headers `(("User-Agent" . ,www-get-page-title-user-agent))))
      (with-current-buffer (url-retrieve-synchronously url)
        (let* ((dom (libxml-parse-html-region url-http-end-of-headers (point-max)))
               (title (dom-text (dom-by-tag dom 'title)))
               (coding (detect-coding-string title 'utf-8)))
          (replace-regexp-in-string "\\(\s+\\|\n\\)" "" (decode-coding-string title coding))))))

  (defun org-capture--wish-list-with-url ()
    (let* ((url (read-from-minibuffer "url: "))
           (title (www-get-page-title url)))
      url title))
  :custom
  (org-use-speed-commands . t)
  (org-startup-folded . 'content)
  (org-directory . "~/org")
  (org-agenda-files . `(,org-directory))
  (org-agenda-window-setup . 'current-window)
  (org-todo-keywords . '((sequence "TODO(t)" "WAIT(w)" "|" "DONE(x)" "SOMEDAY(s)")))
  (org-log-done . 'time)
  (org-agenda-custom-commands
   .
   '(("n" "Agenda and all TODOs"
      ((agenda "" nil)
       (alltodo "" nil))
      nil)
     ("d" "Daily review"
      agenda ""
      ((org-agenda-start-day "1d")
       (org-agenda-span 1)
       ;; (org-agenda-start-with-log-mode '(closed))
       (org-agenda-archives-mode t)))
       ;;(org-agenda-skip-function '(org-agenda-skip-entry-if 'notregexp "^\\*\\* DONE "))))
     ("w" "Weekly review"
      agenda ""
      ((org-agenda-start-day "-7d")
       (org-agenda-span 14)
       (org-agenda-start-on-weekday 1)
       (org-agenda-start-with-log-mode '(closed))
       (org-agenda-archives-mode t)
       (org-agenda-skip-function '(org-agenda-skip-entry-if 'notregexp "^\\*\\* DONE "))))))
  (org-capture-templates
   .
   `(("T" "todo" entry
      (file+headline ,(concat org-directory "/tasks.org") "tasks")
      "** TODO %?\n")
     ("t" "todo" entry
      (file+headline ,(concat org-directory "/tasks.org") "tasks")
      "** TODO %?\nSCHEDULED: %^t\n")
     ("i" "interrupt" entry
      (file+headline ,(concat org-directory "/tasks.org") "tasks")
      "** TODO %?\n" :clock-in t :clock-resume t)
     ("W" "wish list" checkitem
      (file+headline ,(concat org-directory "/notes.org") "wish list")
      "[ ] %?\n")
     ;; ("w" "wish list with url" checkitem
     ;;  (file+function ,(concat org-directory "/notes.org") org-capture--wish-list-with-url)
     ;;  "[ ] [[
  ))
  :bind (("C-c c" . org-capture)
         ("C-C a" . org-agenda)
         ("C-c o" . (lambda ()
                      (interactive)
                      (find-file org-directory))))
  :config
  (leaf orgtbl-aggregate :ensure t))

(leaf whitespace
  :hook
  (before-save-hook . whitespace-cleanup)
  :custom
  (whitespace-space-regexp . "\\(\u3000+\\)")
  (whitespace-style . '(face trailing spaces empty space-mark tab-mark))
  (whitespace-display-mappings . '((space-mark ?\u3000 [?\u25a1]) (tab-mark ?\t [?\u00bb ?\t] [?\\ ?\t])))
  (whitespace-action . '(auto-cleanup))
  :global-minor-mode global-whitespace-mode)

;; (leaf browse-at-remote
;;   :ensure t
;;   :preface
;;   (defun my:copy-url-at-remote ()
;;     (interactive)
;;     (let ((url (browse-at-remote-get-url)))
;;       (kill-new url)
;;     (message "URL: %s" url)))
;;   :bind (("C-c g g" . my:copy-url-at-remote)
;;          ("C-c g o" . browse-at-remote)))

(leaf company
  :ensure t
  :bind ("C-c i" . company-complete)
  :custom
  (company-files . t)
  (company-idle-delay . nil)
  (company-section-wrap-around . t)
  :config
  (leaf company-statistics :ensure t :global-minor-mode company-statistics-mode)
  (leaf company-c-headers :ensure t :config (add-to-list 'company-backends 'company-c-headers))
  (leaf company-shell :ensure t :config (add-to-list 'company-backends 'company-shell))
  (leaf company-terraform :ensure t :config (add-to-list 'company-backends 'company-terraform))
  (leaf company-go :ensure t :config (add-to-list 'company-backends 'company-go))
  (leaf company-nginx :ensure t :config (add-to-list 'company-backends 'company-nginx))
  :global-minor-mode global-company-mode)

(leaf ddskk
  :ensure t
  :custom
  (default-input-method . "japanese-skk")
  (skk-status-indicator . 'minor-mode)
  (skk-egg-like-newline . t)
  (skk-latin-mode-string . "a")
  (skk-hiragana-mode-string . "あ")
  (skk-katakana-mode-string . "ア")
  (skk-jisx0208-latin-mode-string . "Ａ")
  :config
  (let ((jisyo (locate-user-emacs-file "jisyo")))
    (unless (file-directory-p jisyo)
      (skk-get jisyo))))

(leaf dockerfile-mode :ensure t)

(leaf editorconfig :ensure t)

;; (leaf flycheck
;;   :ensure t
;;   :bind (("M-n" . flycheck-next-error)
;;          ("M-p" . flycheck-previous-error))
;;   :custom
;;   (flycheck-display-errors-delay . 0.3)
;;   (flycheck-disabled-checkers . '(emacs-lisp-checkdoc))
;;   :config
;;   (leaf flycheck-inline :ensure t :hook (flycheck-mode-hook . flycheck-inline-mode))
;;   :global-minor-mode global-flycheck-mode)

(leaf folding :ensure t)

(leaf k8s-mode :ensure t)

(leaf lua-mode :ensure t)

(leaf macrostep :ensure t :bind ("C-c e" . macrostep-expand))

(leaf magit :ensure t)

(leaf markdown-mode :ensure t)

(leaf open-junk-file
  :preface
  (defun my:open-junk-file-delete-files ()
    (when (and
           (boundp 'my:open-junk-file-directory)
           (file-directory-p my:open-junk-file-directory))
      (dolist (x
               (directory-files my:open-junk-file-directory t "^\\([^.]\\|\\.[^.]\\|\\.\\..\\)"))
        (delete-file x))))
  :ensure t
  :bind ("C-c j" . open-junk-file)
  :hook (kill-emacs-hook . my:open-junk-file-delete-files)
  :init
  (setq my:open-junk-file-directory (locate-user-emacs-file "junk/"))
  (setq open-junk-file-format (concat my:open-junk-file-directory "%s.")))

(leaf popwin
  :ensure t
  :config
  (mapcar
   #'(lambda (x) (push x popwin:special-display-config))
   '(("*Buffer List*")
     ("*eshell*" :height 30 :dedicated t :stick t)
     ("*Warnings*")))
  :global-minor-mode popwin-mode)

(leaf rainbow-mode :ensure t)

(leaf terraform-mode
  :ensure t
  :hook (terraform-mode-hook . terraform-format-on-save-mode)
  :config
  (leaf terraform-doc :ensure t))

(leaf typescript-mode :ensure t)

(leaf xclip
  :if (or (executable-find "xclip")
          (executable-find "xsel")
          (executable-find "wl-copy")
          (executable-find "pbcopy"))
  :ensure t
  :global-minor-mode xclip-mode)

(leaf yaml-mode :ensure t)
