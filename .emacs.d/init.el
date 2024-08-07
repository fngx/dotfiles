;;; init.el --- -*- lexical-binding: t; -*-

(require 'chemacs
         (expand-file-name "chemacs.el"
                           (file-name-directory
                            (file-truename load-file-name))))
(chemacs-load-user-init)

;; this must be here to keep the package system happy, normally you do
;; `package-initialize' for real in your own init.el
;; (package-initialize)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;(require 'package)
;; Any add to list for package-archives (to add marmalade or melpa) goes here
;;(add-to-list 'package-archives 
;;    '("MELPA" .
;;      "http://melpa.org/packages/"))
;;(package-initialize)

(setq package-archives
      '(("gnu" . "https://elpa.gnu.org/packages/")
        ("gnu-devel" . "https://elpa.gnu.org/devel/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa" . "https://melpa.org/packages/")))



(defvar elpaca-installer-version 0.7)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                 ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                 ,@(when-let ((depth (plist-get order :depth)))
                                                     (list (format "--depth=%d" depth) "--no-single-branch"))
                                                 ,(plist-get order :repo) ,repo))))
                 ((zerop (call-process "git" nil buffer t "checkout"
                                       (or (plist-get order :ref) "--"))))
                 (emacs (concat invocation-directory invocation-name))
                 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                       "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                 ((require 'elpaca))
                 ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))



;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable use-package :ensure support for Elpaca.
  (elpaca-use-package-mode))

;;--------------------------------------------------------------------------------

(use-package org-journal
  :ensure t
  :demand t
;;  :init
;;  (my-leader-def
;;    :infix "oj"
;;    "" '(:which-key "org-journal")
;;    "j" 'org-journal-new-entry
;;    "o" 'org-journal-open-current-journal-file
;;    "s" 'org-journal-tags-status)
;;  :after org
  :config
  (setq org-journal-dir (concat org-directory "/journal"))
  (setq org-journal-file-type 'weekly)
  ;;(setq org-journal-file-format "%Y-%m-%d.org")
  ;;(setq org-journal-date-format "%A, %Y-%m-%d : %U")
  (setq org-journal-file-format "%Y-%m-%d(W%V).org")
  (setq org-journal-date-format "%B %d, %Y (%A)")
  (setq org-journal-enable-encryption t)
  (setq org-journal-time-format-post-midnight "PM: %R ")
  (setq org-journal-created-property-timestamp-format "%Y%m%V%d")
  (setq org-journal-file-header "#+title: Weekly Journal %B %Y - Week %V\n#+startup: folded\n#+category: Journal")
  (setq org-journal-enable-agenda-integration t))


;;--------------------------------------------------------------------------------

;; https://drollery.org/emacs/
(use-package persistent-scratch
  :ensure t
  :demand t
  :config
  (persistent-scratch-setup-default))



;(require 'key-chord)
;(key-chord-mode 1)
;(key-chord-define-global ",," #'crux-switch-to-previous-buffer)

(use-package crux
  :ensure t
  :demand t)

(use-package key-chord
  :ensure t
  :demand t
  :config
  (key-chord-mode 1)
  (key-chord-define-global ",," #'crux-switch-to-previous-buffer))


(use-package treemacs
  :ensure t
  :demand t
  )

(use-package markdown-mode
  :ensure t
  :demand t
  )

(use-package eat
  :ensure (:type git
		   :host codeberg
		   :repo "akib/emacs-eat"
		   :files ("*.el" ("term" "term/*.el") "*.texi"
			   "*.ti" ("terminfo/e" "terminfo/e/*")
			   ("terminfo/65" "terminfo/65/*")
			   ("integration" "integration/*")
			   (:exclude ".dir-locals.el" "*-tests.el")))
  :commands (eat eat-eshell-mode)
  ;; :general
  ;; ("M-o t" 'eat)
  ;; ("M-o T" 'eat-other-window)
  :config
  (eat-compile-terminfo))
(add-hook 'eshell-load-hook #'eat-eshell-mode)


(setq org-support-shift-select t)
(save-place-mode 1)
(recentf-mode 1)
(savehist-mode)
(setq savehist-additional-variables '(kill-ring search-ring regexp-search-ring))
(column-number-mode)

;; show time / load average
(add-to-list 'tab-bar-format 'tab-bar-format-align-right 'append)
(add-to-list 'tab-bar-format 'tab-bar-format-global 'append)
(setq display-time-format "%a %F %T")
(setq display-time-interval 1)
(display-time-mode)


;; Highlight the current line
(let ((hl-line-hooks '(text-mode-hook prog-mode-hook)))
  (mapc (lambda (hook) (add-hook hook 'hl-line-mode)) hl-line-hooks))

;; indentation
(set-default 'indent-tabs-mode nil)

(global-set-key (kbd "C-M-<left>")  'windmove-left)
(global-set-key (kbd "C-M-<right>") 'windmove-right)
(global-set-key (kbd "C-M-<up>")    'windmove-up)
(global-set-key (kbd "C-M-<down>")  'windmove-down)
