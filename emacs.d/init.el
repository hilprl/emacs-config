;;; -*- lexical-binding: t; -*-
(add-hook 'after-init-hook
          `(lambda ()
             (setq gc-cons-threshold ,gc-cons-threshold))
          'append)
(setq gc-cons-threshold most-positive-fixnum)

(defun bootstrap-use-package ()
  "Load `use-package' possibly installing it beforehand"
  (if (locate-library "package")
      (progn
        (require 'package)
        (setq package-user-dir (locate-user-emacs-file
                                (concat
                                 (file-name-as-directory "elpa")
                                 emacs-version)))
        (setq package-archives
              '(("gnu"          . "https://elpa.gnu.org/packages/")
                ("marmalade"    . "https://marmalade-repo.org/packages/")
                ("melpa"        . "https://melpa.org/packages/")
                ("melpa-stable" . "https://stable.melpa.org/packages/")
                ("org"          . "https://orgmode.org/elpa/"))
              package-archive-priorities
              '(("org"          . 20)
                ("melpa-stable" . 15)
                ("gnu"          . 10)
                ("melpa"        . 5)
                ("marmalade"    . 0)))
        (setq package-enable-at-startup nil)
        (package-initialize)
        (unless (package-installed-p 'use-package)
          (package-refresh-contents)
          (package-install 'use-package))
        (setq use-package-enable-imenu-support t)
        (require 'use-package))
    (message "WARNING: Ancient emacs! No advice-add, package.el")
    (defmacro advice-add (&rest body))
    (defmacro use-package (&rest body)))
  (use-package diminish :ensure t :defer t)
  (use-package bind-key :ensure t :defer t))
(bootstrap-use-package)


(add-to-list 'load-path "~/.emacs.d/vifon")
(add-to-list 'load-path "~/.emacs.d/modules")
(setq custom-file "~/.emacs.d/custom.el")
(load custom-file 'noerror)

(use-package hydra :pin melpa :ensure t :defer t)

(require 'my-el-patch)
(require 'my-hooks)
(require 'my-skeletons)
(require 'my-mode-line)
(require 'my-fun)
(require 'my-keys)
(require 'my-ivy)
(require 'my-org)
(require 'my-eshell)
(require 'my-registers)
(require 'my-settings)
(require 'my-scratch)
(when (getenv "START_EXWM")
  (require 'my-exwm)
  (setenv "START_EXWM"))

(require 'pastes-from-web)


(use-package s :ensure t :defer t)
(use-package paredit
  :ensure t
  :diminish "[()]"
  :commands (paredit-mode paredit-kill)
  :init (progn
          (setq paredit-space-for-delimiter-predicates
                '((lambda (endp delimiter) nil)))
          (defun paredit-kill-maybe (arg)
            (interactive "P")
            (if (consp arg)
                (paredit-kill)
              (kill-line arg)))
          (add-hook 'emacs-lisp-mode-hook #'paredit-mode))
  :config (progn
            (define-key paredit-mode-map (kbd "M-s") nil)
            (define-key paredit-mode-map (kbd "M-s M-s") 'paredit-splice-sexp))
  :bind (([remap kill-line] . paredit-kill-maybe)))

(use-package yafolding
  :ensure t
  :defer t
  :init (add-hook 'prog-mode-hook #'yafolding-mode)
  :config (advice-add 'yafolding-go-parent-element :around
                      (defun yafolding-python-fix (orig-fun &rest args)
                        (if (eq major-mode 'python-mode)
                            (python-nav-backward-up-list)
                          (apply orig-fun args)))))

(use-package hideshow-org
  :ensure t
  :commands hs-org/minor-mode)

(use-package folding
  :ensure t
  :commands folding-mode
  :config (folding-add-to-marks-list 'cperl-mode
                                     "=over" "=back"))

(use-package dired
  :bind (:map dired-mode-map
         ("z" . dired-subtree-toggle)
         ("TAB" . dired-submodes-hydra/body)
         ("K" . vifon/dired-subdir-toggle)
         ("* C" . vifon/dired-change-marks*))
  :config (progn
            (setq dired-dwim-target nil
                  dired-free-space-args "-Pkh"
                  dired-ls-F-marks-symlinks t
                  dired-isearch-filenames 'dwim
                  dired-omit-files "^\\.?#\\|^\\.[^\\.]\\|^\\.\\.."
                  wdired-allow-to-change-permissions t
                  image-dired-external-viewer "sxiv")

            ;; Easy switching between the pleasant dired switches and
            ;; the POSIX compliant ones to use with TRAMP when
            ;; connecting to non-GNU systems.
            (let ((portable "-alh"))
              (defun vifon/dired-switches-default ()
                (interactive)
                (setq dired-listing-switches
                      (flags-nonportable portable "ls"
                                         "--group-directories-first"
                                         "-v")))
              (defun vifon/dired-switches-compat ()
                (interactive)
                (setq dired-listing-switches portable)))
            (vifon/dired-switches-default)

            (defun vifon/dired-subdir-toggle ()
              (interactive)
              (if (equal (dired-current-directory)
                         (expand-file-name default-directory))
                  (call-interactively #'dired-maybe-insert-subdir)
                (dired-kill-subdir)
                (pop-to-mark-command)))

            (defun vifon/dired-change-marks* (&optional new)
              (interactive
               (let* ((cursor-in-echo-area t)
                      (new (progn (message "Change * marks to (new mark): ")
                                  (read-char))))
                 (list new)))
              (dired-change-marks ?* new))))

(use-package dired-x
  :init (setq dired-x-hands-off-my-keys t))

(use-package dired-subtree
  :ensure t
  :commands dired-subtree-toggle)

(use-package dired-filter
  :ensure t
  :config (setq-default dired-filter-stack '()))

(use-package dired-rifle
  :ensure t)

(use-package dired-collapse
  :ensure t)

(use-package dired-async
  :ensure async
  :commands dired-async-mode
  :config (setq dired-async-message-function
                (lambda (text face &rest args)
                  (call-process "notify-send" nil 0 nil
                                "Emacs: dired-async"
                                (apply #'format text args))
                  (apply #'dired-async-mode-line-message text face args))))

(use-package dired-recent
  :ensure t
  :init (dired-recent-mode 1))

(use-package ibuffer
  :bind (:map ibuffer-mode-map
         ("/ V" . ibuffer-vc-set-filter-groups-by-vc-root)
         ("/ T" . ibuffer-tramp-set-filter-groups-by-tramp-connection))
  :config (progn
            (global-set-key (kbd "C-x C-b")
                            (if (fboundp #'ibuffer-jump)
                                #'ibuffer-jump
                              #'ibuffer))

            (add-hook 'ibuffer-mode-hook
                      (lambda ()
                        (setq ibuffer-sorting-mode 'filename/process)))
            (setq ibuffer-show-empty-filter-groups nil)
            (setq ibuffer-expert t)
            (setq ibuffer-formats
                  `((mark modified read-only
                          ,@(when (version<= "26.1" emacs-version)
                              '(locked))
                          " "
                          (name 32 32 :left :elide)
                          " "
                          (size 9 -1 :right)
                          " "
                          (mode 16 64 :left :elide)
                          " " filename-and-process)
                    (mark " "
                          (name 32 -1)
                          " " filename)))))

(use-package ibuffer-vc
  :ensure t
  :commands ibuffer-vc-set-filter-groups-by-vc-root)

(use-package ibuffer-tramp
  :ensure t
  :commands ibuffer-tramp-set-filter-groups-by-tramp-connection)

(use-package yasnippet
  :ensure t
  :defer 7
  :diminish yas-minor-mode
  :commands yas-global-mode
  :mode ("emacs\\.d/snippets/" . snippet-mode)
  :init (setq yas-snippet-dirs '("~/.emacs.d/snippets"))
  :config (yas-global-mode 1))

(use-package yasnippet-snippets
  :ensure t
  :after yasnippet)

(use-package auto-yasnippet
  :ensure t
  :bind (("C-c Y" . aya-create)
         ("C-c y" . aya-expand-with-indent))
  :config (defun aya-expand-with-indent (arg)
            (interactive "P")
            (aya-expand)
            (unless arg
              (indent-for-tab-command))))

(use-package tiny
  :ensure t
  :bind ("C-:" . tiny-expand))

(use-package auctex
  :ensure t
  :defer t
  :init (setq preview-scale-function 2.0)
  :config (defun my-auctex-build-pdf ()
            (interactive)
            (TeX-command "LaTeX" 'TeX-master-file)))

(use-package web-mode
  :ensure t
  :mode (("\\.html\\'"      . web-mode)
         ("\\.html\\.[^.]+\\'" . web-mode)
         ("\\.tt\\'"        . web-mode)
         ("\\.vue\\'"       . web-mode)
         ("\\.css\\'"       . web-css-mode)
         ("\\.scss\\'"      . web-css-mode))
  :config (progn
            (define-derived-mode web-css-mode web-mode "WebCSS")
            (setq web-mode-markup-indent-offset 2
                  web-mode-css-indent-offset 2
                  web-mode-code-indent-offset 2)
            (setq web-mode-engines-alist
                  '(("jinja" . "\\.j2\\'")
                    ("jinja" . "\\.html\\'")))
            ;; Fix Jinja2 autopairing; was producing: "{{  }}}}".
            (setq web-mode-enable-auto-pairing nil)
            (add-to-list 'company-backends 'company-css)))

(use-package emmet-mode
  :ensure t
  :pin melpa
  :commands emmet-mode
  :init (mapc (lambda (mode)
                (add-hook mode  #'emmet-mode))
              '(web-mode-hook
                html-mode-hook
                css-mode-hook))
  :config (progn
            (setq emmet-self-closing-tag-style " /")
            (add-to-list 'emmet-css-major-modes 'web-css-mode)))

(use-package legalese
  :ensure t
  :commands legalese
  :init (defun legalese-box (ask)
          (interactive "P")
          (let ((comment-style 'box))
            (legalese ask))))

(use-package minimap
  :ensure t
  :bind ("C-c n" . minimap-mode)
  :config (setq minimap-window-location 'right))

(use-package transpose-frame
  :ensure t
  :bind (("C-x 4 t" . transpose-frame)
         ("C-x 4 i" . flop-frame)
         ("C-x 4 I" . flip-frame)))

(use-package vim-line-open
  :bind ("C-o" . open-next-line-dwim))

(use-package evil-nerd-commenter
  :ensure t
  :init (defun evil-nerd-commenter-dwim (arg)
          (interactive "P")
          (if arg
              (evilnc-comment-or-uncomment-lines arg)
            (call-interactively 'comment-dwim)))
  :bind (([remap comment-dwim] . evil-nerd-commenter-dwim)))

(use-package treemacs
  :ensure t
  :bind (("C-c b" . treemacs)
         :map treemacs-mode-map
         ("j" . treemacs-next-line)
         ("k" . treemacs-previous-line)
         ("W" . treemacs-switch-workspace)))

(use-package magit
  :ensure t
  :commands magit-process-file
  :bind (("C-c g" . magit-status)
         ("C-x M-g" . magit-dispatch-popup)
         ("C-c M-g" . magit-file-popup))
  :init (progn
          (setq magit-last-seen-setup-instructions "1.4.0")
          (setq magit-diff-refine-hunk t)
          (setq magit-completing-read-function #'ivy-completing-read))
  :config (progn
            (mapcar
             (lambda (keymap)
               (define-key keymap (kbd "M-<tab>") #'magit-section-cycle)
               (define-key keymap (kbd "C-<tab>") nil))
             (list magit-status-mode-map
                   magit-log-mode-map
                   magit-reflog-mode-map
                   magit-refs-mode-map
                   magit-diff-mode-map))
            (magit-define-popup-switch 'magit-log-popup ?F "first parent" "--first-parent")
            (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)))

(use-package magit-todos :ensure t :defer t)

(use-package git-commit
  :ensure t
  :mode ("/COMMIT_EDITMSG\\'" . git-commit-mode)
  :config (progn
            (define-key git-commit-mode-map (kbd "C-c C-l") 'magit-log)
            (add-hook 'git-commit-mode-hook (defun turn-on-flyspell ()
                                              (flyspell-mode 1)))))

(use-package git-messenger
  :ensure t
  :bind ("C-x v p" . git-messenger:popup-message))

(use-package git-timemachine
  :ensure t
  :bind ("C-x v t" . git-timemachine))

(use-package git-link
  :ensure t
  :bind ("C-x v w" . git-link)
  :config (setq git-link-default-branch "master"))

(use-package goto-last-change
  :ensure t
  :demand t
  :bind ("C-x C-\\" . goto-last-change))

(use-package symbol-overlay
  :ensure t
  :pin melpa
  :bind (("M-p" . symbol-overlay-jump-prev)
         ("M-n" . symbol-overlay-jump-next)
         ("C-;" . symbol-overlay-put)
         ("<f10>" . symbol-overlay-remove-all)
         :map symbol-overlay-map
         ("b" . symbol-overlay-switch-backward)
         ("f" . symbol-overlay-switch-forward)))

(use-package indent-guide
  :ensure t
  :defer t
  :init (add-hook 'LaTeX-mode-hook (lambda ()
                                     (indent-guide-mode 1)))
  :config (setq indent-guide-delay nil))

(use-package writeroom-mode
  :ensure t
  :defer t)

(use-package olivetti
  :ensure t
  :defer t)

(use-package presentation
  :ensure t
  :commands presentation-mode)

(use-package highlight-defined
  :ensure t
  :commands highlight-defined-mode)

(use-package visual-regexp
  :ensure t
  :defer t
  :bind (([remap query-replace-regexp] . vr/query-replace)))
(use-package visual-regexp-steroids
  :ensure t
  :after visual-regexp)

(use-package volatile-highlights
  :ensure t
  :diminish volatile-highlights-mode
  :config (volatile-highlights-mode 1))

(use-package beacon
  :ensure t
  :diminish beacon-mode
  :config (beacon-mode 1))

(use-package phi-search
  :ensure t
  :commands (phi-search phi-search-backward))
(use-package multiple-cursors
  :ensure t
  :demand t                             ;C-v/M-v don't work otherwise
  :bind (("C-<"         . mc/mark-previous-like-this)
         ("C->"         . mc/mark-more-like-this-extended)
         ("C-*"         . mc/mark-all-like-this-dwim)
         ("C-M-;"       . mc/mark-all-like-this-dwim)
         ("M-<mouse-1>" . mc/add-cursor-on-click))
  :init (global-unset-key (kbd "M-<down-mouse-1>"))
  :config (progn
            (define-key mc/keymap (kbd "C-s") 'phi-search)
            (define-key mc/keymap (kbd "C-r") 'phi-search-backward)))

(use-package expand-region
  :ensure t
  :bind (("C-=" . er/expand-region)
         ("M-S-<SPC>" . er/expand-region)))

(use-package semantic/decorate/mode
  :defer t
  :config (setq-default semantic-decoration-styles
                        '(("semantic-decoration-on-includes" . t))))

(use-package semantic
  :defer t
  :config (setq semantic-default-submodes
                '(global-semantic-idle-scheduler-mode
                  global-semanticdb-minor-mode
                  global-semantic-decoration-mode
                  global-semantic-stickyfunc-mode)))

(use-package company
  :ensure t
  :defer 5
  :config (progn
            (setq company-idle-delay 0.25)
            (add-hook 'eshell-mode-hook (lambda ()
                                          (company-mode 0)))
            (add-hook 'org-mode-hook (lambda ()
                                       (company-mode 0)))
            (global-company-mode 1))
  :init (add-hook 'c++-mode-hook
                  (lambda ()
                    (setq-local company-clang-arguments '("-std=c++14"))))
  :bind (("C-c v" . company-complete)
         ("C-c /" . company-files)))

(use-package company-clang
  :after company
  :bind ("C-c V" . company-clang))

(use-package company-tern
  :ensure t
  :commands company-tern
  :init (add-hook 'js-mode-hook
                  (lambda ()
                    (require 'company)
                    (add-to-list (make-local-variable 'company-backends)
                                 'company-tern))))

(use-package tern
  :ensure t
  :commands tern-mode
  :init (add-hook 'js-mode-hook (lambda () (tern-mode 1)))
  :config (setq tern-command (append tern-command '("--no-port-file"))))

(use-package ggtags
  :ensure t
  :demand t        ;bad things happen in the globalized mode otherwise
  :init (define-globalized-minor-mode global-ggtags-mode ggtags-mode
          (lambda ()
            (when (derived-mode-p 'c-mode 'c++-mode 'java-mode)
              (ggtags-mode 1)))))

(use-package rtags
  :if (file-directory-p "~/local/share/emacs/site-lisp/rtags")
  :load-path "~/local/share/emacs/site-lisp/rtags"
  :commands (rtags-minor-mode global-rtags-minor-mode)
  :config (progn
            (define-minor-mode rtags-minor-mode
              nil
              :lighter " RTags"
              :keymap (let ((m (make-sparse-keymap)))
                        (rtags-enable-standard-keybindings m (kbd "C-c C-r"))
                        (define-key m (kbd "M-.") #'rtags-find-symbol-at-point)
                        (define-key m (kbd "M-,") #'rtags-location-stack-back)
                        (define-key m (kbd "M-]") #'rtags-find-references-at-point)
                        m))
            (define-globalized-minor-mode global-rtags-minor-mode rtags-minor-mode
              (lambda ()
                (when (derived-mode-p 'c-mode 'c++-mode)
                  (rtags-minor-mode 1))))
            (require 'company)
            (add-to-list 'company-backends 'company-rtags)
            (setq rtags-autostart-diagnostics t)
            (setq rtags-completions-enabled t)))

(use-package flycheck
  :ensure t
  :defer t
  :init (progn
          (add-hook 'c-mode-hook (lambda ()
                                   (setq flycheck-clang-language-standard "c14")))
          (add-hook 'c++-mode-hook (lambda ()
                                     (setq flycheck-clang-language-standard "c++14")))))

(use-package cmake-mode
  :ensure t
  :defer t)

(use-package avy
  :ensure t
  :bind ("C-c j" . avy-dwim)
  :config (setq avy-single-candidate-jump nil)
  :init (progn
          (avy-setup-default)
          (defun avy-dwim (arg)
            (interactive "P")
            (cond ((not arg)
                   (call-interactively #'avy-goto-word-1))
                  ((equal arg '(4))
                   (call-interactively #'avy-goto-char))
                  ((equal arg '(16))
                   (avy-goto-line))
                  (t nil)))))

(use-package win-switch
  :ensure t
  :bind ("C-x o" . win-switch-dispatch)
  :config (setq win-switch-window-threshold 2))

(use-package winner
  :bind (("C-c z" . winner-undo)
         :map winner-mode-map
         ("<XF86Back>"    . winner-undo)
         ("<XF86Forward>" . winner-redo))
  :init (winner-mode 1))

(use-package c-c++-header
  :mode ("\\.h\\'" . c-c++-header)
  :init (defalias 'h++-mode 'c++-mode))

(use-package uniquify
  :config (setq uniquify-buffer-name-style 'post-forward-angle-brackets
                uniquify-strip-common-suffix t))

(use-package deft
  :ensure t
  :bind (("<f5>" . deft))
  :init (setq deft-auto-save-interval 0)
  :config (setq deft-extensions (sort deft-extensions
                                      (lambda (a b)
                                        (equal a "md")))
                deft-default-extension "md"
                deft-markdown-mode-title-level 1))

(use-package markdown-mode
  :ensure t
  :defer t
  :config (add-hook 'markdown-mode-hook
                    (defun my-markdown-mode-hook ()
                      (add-to-list (make-local-variable 'electric-pair-pairs)
                                   '(?` . ?`)))))

(use-package ansible :ensure t :defer t)
(use-package ansible-doc :ensure t :defer t)
(use-package company-ansible :ensure t :defer t)

(use-package yaml-mode
  :ensure t
  :defer t
  :mode ("\\.sls\\'" . yaml-mode)       ;Saltstack files
  :config (progn
            (add-hook 'yaml-mode-hook (lambda () (ansible 1)))
            (add-hook 'yaml-mode-hook
                      (lambda ()
                        (add-to-list (make-local-variable 'company-backends)
                                     'company-ansible)))))

(use-package pod-mode
  :mode ("\\.pod$" . pod-mode))

(use-package dumb-jump
  :ensure t
  :config (setq dumb-jump-selector 'ivy))

(use-package vlf
  :ensure t
  :init (require 'vlf-setup))

(use-package haskell-mode
  :ensure t
  :defer t
  :config (progn
            (setq haskell-program-name "cabal repl")
            (add-hook 'haskell-mode-hook #'interactive-haskell-mode)))

(use-package cperl-mode
  :commands cperl-mode
  :init (progn
          (defalias 'perl-mode 'cperl-mode)
          (setq cperl-indent-level 4
                cperl-close-paren-offset -4
                cperl-continued-statement-offset 4
                cperl-indent-parens-as-block t
                cperl-tab-always-indent t)
          (defun perl-method-call-dwim (arg)
            (interactive "P")
            (let ((inside-comment-or-string-p
                   (lambda () (nth 8 (syntax-ppss))))
                  (cursor-not-after-word-p
                   (lambda ()
                     (save-excursion
                       (backward-char)
                       (not (looking-at "[])}[:alpha:]]"))))))
              (if (or arg
                      (funcall inside-comment-or-string-p)
                      (funcall cursor-not-after-word-p))
                  (self-insert-command 1)
                (insert "->")))))
  :config (progn
            (define-key cperl-mode-map (kbd ".") #'perl-method-call-dwim)
            (require 'perltidy)
            (define-key cperl-mode-map (kbd "C-c C-i") #'perltidy-dwim-safe)))

(use-package python
  :defer t
  :config (progn
            (add-hook 'python-mode-hook
                      (defun my-python-hook ()
                        (setq tab-width 4
                              python-indent 4
                              py-indent-offset 4)))))

(use-package anaconda-mode
  :ensure t
  :commands (anaconda-mode
             anaconda-eldoc-mode)
  :init (progn
          (add-hook 'python-mode-hook #'anaconda-mode)
          (add-hook 'python-mode-hook #'anaconda-eldoc-mode)))

(use-package company-anaconda
  :ensure t
  :after company
  :init (add-to-list 'company-backends 'company-anaconda))

(use-package js-mode
  :defer t
  :init (setq-default js-indent-level 2))
(use-package typescript-mode
  :ensure t
  :defer t
  :init (setq-default typescript-indent-level 2))

(use-package projectile
  :ensure t
  :defer 3
  :diminish projectile-mode
  :commands (projectile-global-mode
             projectile-switch-project
             my-projectile-show-path)
  :init (progn
          (setq projectile-switch-project-action (lambda ()
                                                   (dired "."))))
  :bind (:map projectile-command-map
         ("p" . projectile-switch-project)
         ("s r" . rg))
  :bind-keymap ("C-c p" . projectile-command-map)
  :config (progn
            (projectile-mode 1)
            (defun my-projectile-show-path (arg)
              (interactive "P")
              (let ((project-path (if (projectile-project-p)
                                      (file-relative-name buffer-file-name
                                                          (projectile-project-root))
                                    buffer-file-name)))
                (when arg
                  (kill-new project-path))
                (message "%s" project-path)))
            (define-key projectile-command-map (kbd "C-f") #'my-projectile-show-path)
            (setq projectile-completion-system 'ivy)
            (setq projectile-ignored-project-function
                  (lambda (path)
                    (or (file-remote-p path)
                        (string-prefix-p "/media/" path))))))

(use-package rg
  :ensure t
  :commands rg
  :bind ("M-s ," . rg-dwim))

(use-package sane-term
  :ensure t
  :init (setq sane-term-shell-command (getenv "SHELL"))
  :config (add-hook 'term-mode-hook
                    (lambda ()
                      (yas-minor-mode -1)))
  :bind (("C-x t" . sane-term)
         ("C-x T" . sane-term-create)))

(use-package zop-to-char
  :ensure t
  :bind (("M-Z" . zop-up-to-char)))

(use-package diff-hl
  :ensure t
  :defer 2
  :bind ("C-x v \\" . diff-hl-amend-mode)
  :config (progn
            (global-diff-hl-mode 1)))

(use-package image-mode
  :defer t
  :config (progn
            (define-key image-mode-map (kbd "k")
              (lambda (arg)
                (interactive "P")
                (if arg
                    (kill-buffer)
                  (kill-buffer-and-window))))
            (define-key image-mode-map (kbd "K")
              (lambda ()
                (interactive)
                (kill-buffer-and-window)))))

(use-package ledger-mode
  :ensure t
  :defer t
  :bind (:map ledger-mode-map
         ("<C-tab>" . nil)
         ("C-M-i" . completion-at-point))
  :config (progn
            (setq ledger-clear-whole-transactions t
                  ledger-highlight-xact-under-point nil
                  ledger-default-date-format ledger-iso-date-format
                  ledger-reconcile-default-commodity "PLN"
                  ledger-post-amount-alignment-at :end)
            (defun vifon/delete-blank-lines (&rest ignored)
              "Same as `delete-blank-lines' but accept (and
ignore) any passed arguments to work as an advice."
              (let ((point (point)))
                (goto-char (point-max))
                (delete-blank-lines)
                (goto-char point)))
            (advice-add #'ledger-add-transaction :after
                        #'vifon/delete-blank-lines)
            (advice-add #'ledger-fully-complete-xact :after
                        #'vifon/delete-blank-lines)))

(use-package circe
  :ensure t
  :defer t
  :if (file-directory-p "~/.password-store/emacs/circe")
  :bind (:map lui-mode-map
         ("C-c C-w" . lui-track-bar-move)
         :map circe-mode-map
         ("C-c C-q". bury-buffer))
  :config (progn
            (setq circe-server-buffer-name "Circe:{network}")
            (let ((servers (eval (read (shell-command-to-string
                                        "pass emacs/circe/servers.el")))))
              (setq circe-network-options servers))

            (setq circe-reduce-lurker-spam t)

            (setq circe-use-cycle-completion t)

            (setq circe-format-server-topic
                  (replace-regexp-in-string "{new-topic}"
                                            "{topic-diff}"
                                            circe-format-server-topic))

            (enable-circe-color-nicks)
            (setq circe-color-nicks-everywhere t)

            (enable-lui-track-bar)

            (define-key lui-mode-map (kbd "C-c C-o")
              (lambda ()
                (interactive)
                (ffap-next-url t)))))

(use-package notmuch
  :ensure t
  :if (and (file-directory-p "~/Mail/.notmuch")
           (file-regular-p   "~/.emacs.d/secret/notmuch-fcc"))
  :bind (("<f7>" . notmuch))
  :config (progn
            (setq notmuch-fcc-dirs
                  (let ((tags "-new -unread -inbox +sent"))
                    (mapcar
                     (lambda (rule)
                       (let ((account (car rule))
                             (folder  (cdr rule)))
                         (cons account (format "\"%s\" %s"
                                               folder tags))))
                     (with-temp-buffer
                       (insert-file-contents "~/.emacs.d/secret/notmuch-fcc")
                       ;; Format:
                       ;;   (("me@example.com"   . "me@example.com/Sent")
                       ;;    ("alsome@gmail.com" . "alsome@gmail.com/Sent Mail"))
                       (goto-char (point-min))
                       (read (current-buffer))))))
            (setq message-signature
                  (lambda ()
                    (let* ((signature-override
                            (concat (file-name-as-directory "~/.signature.d")
                                    (message-sendmail-envelope-from)))
                           (signature-file
                            (if (file-readable-p signature-override)
                                signature-override
                              "~/.signature")))
                      (when (file-readable-p signature-file)
                        (with-temp-buffer
                          (insert-file-contents signature-file)
                          (buffer-string))))))

            (setq message-sendmail-envelope-from 'header)
            (setq notmuch-always-prompt-for-sender t)

            (setq notmuch-wash-signature-lines-max 3)

            (when (file-executable-p "~/.bin/notmuch-sync")
              (defun my-notmuch-poll-and-refresh-this-buffer ()
                (interactive)
                (call-process
                 "notmuch-sync" nil 0 nil
                 (buffer-name (current-buffer)))))

            (dolist (map '(notmuch-hello-mode-map
                           notmuch-show-mode-map))
              (define-key map (kbd "<C-tab>") nil))
            (dolist (map '(notmuch-hello-mode-map
                           notmuch-show-mode-map
                           notmuch-search-mode-map))
              (define-key map (kbd "g") #'notmuch-refresh-this-buffer)
              (when (file-executable-p "~/.bin/notmuch-sync")
                (define-key map (kbd "G") #'my-notmuch-poll-and-refresh-this-buffer)))

            (define-key notmuch-search-mode-map (kbd "A")
              (lambda ()
                (interactive)
                (when (y-or-n-p "Archive all?")
                  (notmuch-search-tag-all '("-unread" "-inbox")))))
            (define-key notmuch-search-mode-map (kbd "D")
              (lambda ()
                (interactive)
                (when (y-or-n-p "Delete all?")
                  (notmuch-search-tag-all '("-unread" "-inbox" "+deleted")))))


            (defun notmuch-clear-search-history ()
              (interactive)
              (when (y-or-n-p "Clear the notmuch search history? ")
                (setq notmuch-search-history nil)
                (notmuch-refresh-this-buffer)))
            (define-key notmuch-hello-mode-map
              (kbd "D") #'notmuch-clear-search-history)
            (define-key notmuch-show-mode-map (kbd "C-c C-o")
              (lambda (arg)
                (interactive "P")
                (if arg
                    (progn
                      (require 'shr)
                      (shr-next-link))
                  (require 'ffap)
                  (ffap-next-url))))

            (define-key notmuch-hello-mode-map
              (kbd "O") (lambda () (interactive)
                          (setq notmuch-search-oldest-first
                                (not notmuch-search-oldest-first))
                          (message "Notmuch search oldest first: %s"
                                   notmuch-search-oldest-first)))

            (defun notmuch-fcc-replace ()
              (interactive)
              (message-remove-header "Fcc")
              (notmuch-fcc-header-setup))))

(use-package cua-base
  :defer t
  :init (progn
          ;; Disabling `cua-global-mark-keep-visible' improves
          ;; performance when typing characters with global-mark
          ;; enabled.
          (setq cua-global-mark-keep-visible nil)

          ;; Do not enable more cua keys than necessary.
          (setq cua-enable-cua-keys nil)

          ;; Using `cua-selection-mode' alone is not enough. It still
          ;; binds C-RET and overrides this keybinding for instance in
          ;; org-mode. I'd rather keep using my hack.
          (global-set-key (kbd "C-S-SPC")
                          (defun cualess-global-mark ()
                            (interactive)
                            (if (version<= "24.4" emacs-version)
                                (cua-selection-mode 1)
                              (cua-mode 1))
                            (call-interactively 'cua-toggle-global-mark)))
          (advice-add 'cua--deactivate-global-mark :after
                      (lambda (ret-value)
                        (cua-mode 0)
                        ret-value))))

(use-package slime
  :ensure t
  :defer t
  :config (when (file-readable-p "~/quicklisp/slime-helper.el")
            (load "~/quicklisp/slime-helper.el")))
(use-package slime-autoloads
  :config (setq inferior-lisp-program "sbcl"))

(use-package rust-mode :ensure t :defer t)
(use-package racer
  :if (file-exists-p "~/.cargo/bin/racer")
  :ensure t
  :after rust-mode
  :init (progn
          (add-hook 'rust-mode-hook #'racer-mode)
          (add-hook 'racer-mode-hook #'eldoc-mode))
  :config (setq racer-rust-src-path
                (concat (file-name-as-directory
                         (substring
                          (shell-command-to-string "rustc --print sysroot")
                          0 -1))
                        "lib/rustlib/src/rust/src")))


(defun my-minibuffer-setup-hook ()
  (setq gc-cons-threshold most-positive-fixnum))
(defun my-minibuffer-exit-hook ()
  (setq gc-cons-threshold 800000))

(add-hook 'minibuffer-setup-hook #'my-minibuffer-setup-hook)
(add-hook 'minibuffer-exit-hook #'my-minibuffer-exit-hook)


(use-package zenburn-theme
  :ensure t
  :config (progn
            (load-theme 'zenburn 'no-confirm)
            (setq frame-background-mode 'dark)
            (ignore-errors
              (let ((font-name "Inconsolata")
                    (font-size "14"))
                (let ((font (concat font-name "-" font-size)))
                  (add-to-list 'default-frame-alist `(font . ,font))
                  (set-frame-font font nil t))))))

;;; DEPRECATION: replaced by "~/.emacs.d/local.el"
(use-package my-secret
  :if (file-directory-p "~/.emacs.d/secret")
  :load-path ("~/.emacs.d/secret"))
;;; /DEPRECATION

(when (file-exists-p "~/.emacs.d/local.el")
  (load "~/.emacs.d/local.el"))

(use-package nlinum
  :ensure t
  :defer t
  :if (not (fboundp #'display-line-numbers-mode)))

(use-package midnight
  :defer 13
  :config (midnight-mode 1))

(use-package aggressive-indent :ensure t :defer t)
(use-package color-identifiers-mode :ensure t :defer t)
(use-package dockerfile-mode :ensure t :defer t)
(use-package dpaste :ensure t :defer t)
(use-package focus-autosave-mode :ensure t :defer t)
(use-package hl-sexp :ensure t :defer t)
(use-package impatient-mode :ensure t :defer t)
(use-package rainbow-mode :ensure t :defer t)
(use-package restclient :ensure t :defer t)
(use-package web-beautify :ensure t :defer t)
(use-package wgrep :ensure t :defer t)
(use-package fish-mode :ensure t :defer t)

;;; Needs to be the last one because otherwise during the installation
;;; (via :ensure) it prompts whether to save ~/.abbrev_defs making it
;;; no longer fully automated. Sadly I've got no idea why it happens.
(use-package ess
  :ensure t
  :defer t
  :config (setq ess-keep-dump-files nil
                ess-delete-dump-files t
                ess-history-file nil))
