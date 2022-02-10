;; init.el -- Emacs init file -*- lexical-binding: t -*-
;; Author: Ricardo Orbegozo
;; updated: 2020-04-13
;; Personal Emacs configuration for Archlinux 
;; Code:

;;; ==================== Accelerate Emacs Starup ====================

(defvar file-name-handler-alist-original file-name-handler-alist)

(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6
      file-name-handler-alist nil
      site-run-file nil)

(defvar arch/gc-cons-threshold 100000000)

(add-hook 'emacs-startup-hook
	  #'(lambda ()
	      (setq gc-cons-threshold arch/gc-cons-threshold
		    gc-cons-percentage 0.1
		    file-name-handler-alist
		    file-name-handler-alist-original)))

(add-hook 'minibuffer-setup-hook
	  #'(lambda ()
	      (setq gc-cons-threshold most-positive-fixnum)))

(add-hook 'minibuffer-exit-hook
	  #'(lambda ()
	      (garbage-collect)
	      (setq gc-cons-threshold arch/gc-cons-threshold)))

;;; ==================== EMACS customization ====================


;;; set CUSTOM user-emacs-directory
(setq my-user-emacs-directory
      (format
       "/run/media/%s/TOSHIBA_EXT/KN28/emacshome/.emacs.d/"
       (getenv "USER")))

(when (equal system-type 'windows-nt)
  (setq user-emacs-directory (expand-file-name "~/.emacs.d/")))

(when (equal system-type 'gnu/linux)
  (if (file-directory-p my-user-emacs-directory)
      (setq user-emacs-directory my-user-emacs-directory)
    (setq user-emacs-directory (expand-file-name "~/.emacs.d/"))))

;; EMACS PACKAGE MANAGMENT

(require 'package)

(add-to-list 'package-archives 
	     '("melpa" . "http://melpa.org/packages/"))
(add-to-list 'package-archives 
	     '("org" . "https://orgmode.org/elpa/"))

(setq package-enable-at-startup nil)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-and-compile
  (setq use-package-always-ensure t
	use-package-expand-minimally t))


;;; Settings without corresponding packages

(use-package emacs
  :init
  (defun show-file-name ()
    "Show the full path file name in the minibuffer."
    (interactive)
    (if (equal current-prefix-arg nil) ; no C-u
	;; then
	(message (buffer-file-name))
      ;; else
      (insert (buffer-file-name))))

  ;; (global-set-key [C-f1] 'show-file-name)

  :bind (("C-ñ 1" . show-file-name)	       ; show file name path
	 ("C-ñ ," . (lambda()(interactive)(insert "<"))); insert symbol <
	 ("C-ñ ." . (lambda()(interactive)(insert ">"))); insert symbol >
	 ("<f1>"  . call-last-kbd-macro)       ; kbd for emacs macro
	 ("C-c d" . insert-date)               ; insert date HH:MM:SS
	 ("<f12>" . display-line-numbers-mode)); show line numbers
  :config
  ;; (setq ring-bell-function 'ignore)         ; don't show "C-g" prompt
  ;; (setq visible-bell nil)

  ;; set fonts according to OS
  (cond
   ((equal system-type 'windows-nt)
    (when (member "DejaVu Sans Mono" (font-family-list))
      (add-to-list 'initial-frame-alist '(font . "Dejavu Sans Mono-10"))
      (add-to-list 'default-frame-alist '(font . "Dejavu Sans Mono-10"))
      (add-hook 'prog-mode-hook 'turn-on-visual-line-mode)
      (add-hook 'text-mode-hook 'turn-on-visual-line-mode)))
   ((equal system-type 'darwin)
    (when (member "Menlo" (font-family-list))
      (set-frame-font "Menlo" t t)))
   ((equal system-type 'gnu/linux)
    (when (member "DejaVu Sans Mono" (font-family-list))
      (set-frame-font "Dejavu Sans Mono-10" t t)
      (add-to-list 'initial-frame-alist '(font . "Dejavu Sans Mono-10"))
      (add-to-list 'default-frame-alist '(font . "Dejavu Sans Mono-10"))
      )))

  ;; show line numbers in:
  ;; programming mode
  (add-hook 'prog-mode-hook 'display-line-numbers-mode)
  ;; text mode
  (add-hook 'text-mode-hook 'display-line-numbers-mode)

  (tool-bar-mode -1)                           ; don't show tool-bar
  (fset 'yes-or-no-p 'y-or-n-p)                ; simplify yes no questions
  (put 'narrow-to-region 'disabled nil)        ; disable query
  ;; (setq-default line-spacing 2)             ; default line space
  (savehist-mode 1)			       ; save minibuffer history
  (setq frame-resize-pixelwise t)              ; resize frames by pixels
  ;; startup directory
  (when (equal system-type 'gnu/linux)
    (if (file-directory-p my-user-emacs-directory)
	(setq default-directory
	      (expand-file-name
	       "../documents/professional/projects/" 
	       user-emacs-directory))
      (setq default-directory (expand-file-name "~/Projects/"))))
  )


(add-to-list 'load-path                      ; add elisp/ to load-path
	     (expand-file-name
	      "elisp"
	      user-emacs-directory))

;; avoid OS overwrite custom user-emacs-directory

(use-package "subr"                        
  :ensure nil
  :config
  (when (equal system-type 'gnu/linux)
      (if (file-directory-p my-user-emacs-directory)
	  (setq user-emacs-directory my-user-emacs-directory)
	(setq user-emacs-directory
	      (expand-file-name "~/.emacs.d/"))))
  ;; (when (equal system-type 'windows-nt)
  ;; 	(setq user-emacs-directory 
  ;; 	      "j:/emacshome/.emacs.d/"))
  )

(setq byte-compile-warnings '(cl-functions))); avoid init warning about cl


;; ========== Builtin packages ==========

(use-package "startup"
  :ensure nil
  :config
  (setq inhibit-startup-message t)
  (setq inhibit-startup-screen t)
  (setq initial-scratch-message 'nil)
  (setq auto-save-list-file-prefix (expand-file-name "../auto-save-list/.saves-" package-user-dir))
  )


;; fix custom theme enable at startup emacs >26.3

(use-package custom
  :ensure nil
  :config
  (if (version<= "26.3"  emacs-version)
      (setq custom--inhibit-theme-enable nil)))

;; emacs update file changes

(use-package autorevert
  :ensure nil
  :config
  (global-auto-revert-mode 1))


;; delete selected region such as MS-Word (word, etc)

(use-package delsel
  :ensure nil
  :config
  (delete-selection-mode 1))


;; backup configuration (inspired by catchestocatches.com)

(use-package files
  :ensure nil
  :config
  (setq confirm-kill-processes nil)
  (setq backup-directory-alist
	`(("." . ,(expand-file-name ".saves" user-emacs-directory))))
  (setq
   backup-by-copying t         ; don't clobber symlinks
   kept-new-versions 20        ; keep 20 latest versions
   kept-old-versions 200       ; don't bother with old versions
   delete-old-versions t       ; don't ask about deleting old versions
   version-control t           ; number backups
   vc-make-backup-files t))    ; backup version controlled files


;; enable list of opened recent files

(use-package recentf
  :ensure nil
  :init  
  (recentf-mode 1)                          ; save recent files
  :config
  (setq recentf-max-menu-items 25)
  (setq recentf-max-saved-items 50)
  (setq recentf-auto-cleanup 'never)        ; don't clean recent files
  ;; (run-at-time nil (* 5 60) 'recentf-save-list) ; save recent files
  :bind (("C-x f" . recentf-open-files)))


;; display line mode with line & column numbers

(use-package simple
  :ensure nil
  :config
  (column-number-mode 1)       ; display column number in modeline 
  (line-number-mode 1)         ; display number in modeline
  (global-visual-line-mode 1)  ; wrap lines
  :bind
  ;; clone indirec buffer, inspired by psychology PhD student
  (("C-x 5 c" . clone-indirect-buffer-other-frame)
   ("C-x O" . (lambda ()(interactive)(other-window -1)))
   ("C-x 5 o" . (lambda ()(interactive)(other-frame -1)))
   ("C-x 5 O" . other-frame)))


;; unset emacs predefined key bindings 

(use-package bind-key
  :ensure nil
  :config
  (dolist (key '("\C-z"        ; minimize frame
		 "\M-q"        ; fill-paragraph (set as "C-. C-f")
		 [?\C-\.]))    ; flyspell-auto-correct-word  (set as "C-M-i")

    (global-unset-key key))    ; is also exists "local-unset-key"
  ;; (unbind-key "C-." flyspell-mode-map)
  )

;; auto complete words

;; (use-package hippie-exp
;;   :ensure nil
;;   :bind ("M-/" . hippie-expand)
;;   :config
;;   (hippie-expand-try-functions-list)
;;   )     


;;; GRAMMAR CORRECTION

(use-package langtool
  :ensure nil
  :load-path "elisp"
  :config
  (when (equal system-type 'gnu/linux)
    (setq langtool-language-tool-jar
	  (if (file-directory-p my-emacs-user-dir)
	      (expand-file-name "../download/LanguageTool-4.9.1/languagetool-commandline.jar")
	    (shell-command-to-string "ls ~/Downloads/Language*/languagetool-commandline.jar | head -n1")
	    )))
  (setq langtool-default-language "en-US")
  (setq langtool-mother-tongue "es")

  (global-set-key "\C-x4w" 'langtool-check)
  (global-set-key "\C-x4W" 'langtool-check-done)
  (global-set-key "\C-x4l" 'langtool-switch-default-language)
  (global-set-key "\C-x44" 'langtool-show-message-at-point)
  (global-set-key "\C-x4c" 'langtool-correct-buffer)

  ;; (add-hook 'org-mode-hook
  ;; 	    (lambda ()
  ;; 	      (add-hook 'after-save-hook 'langtool-check nil 'make-it-local)))

  ;; org-mode

  (eval-after-load 'org-mode
    '(progn
       (setq langtool-generic-check-predicate
	     '(lambda (start end)
		;; set up for `org-mode'
		(let* ((begin-regexp "^[ \t]*#\\+begin_\\(src\\|html\\|latex\\|example\\|quote\\)")
		       (end-regexp "^[ \t]*#\\+end_\\(src\\|html\\|latex\\|example\\|quote\\)")
		       (case-fold-search t)
		       (ignored-font-faces '(org-verbatim
					     org-block-begin-line
					     org-meta-line
					     org-tag
					     org-link
					     org-level-1
					     org-document-info))
		       (rlt t)
		       ff
		       th
		       b e)
		  (save-excursion
		    (goto-char start)

		    ;; get current font face
		    (setq ff (get-text-property start 'face))
		    (if (listp ff) (setq ff (car ff)))

		    ;; ignore certain errors by set rlt to nil
		    (cond
		     ((memq ff ignored-font-faces)
		      ;; check current font face
		      (setq rlt nil))
		     ((string-match "^ *- $" (buffer-substring (line-beginning-position) (+ start 2)))
		      ;; dash character of " - list item 1"
		      (setq rlt nil))
		     ((and (setq th (thing-at-point 'evil-WORD))
			   (or (string-match "^=[^=]*=[,.]?$" th)
			       (string-match "^\\[\\[" th)))
		      ;; embedded cde like =w3m= or org-link [[http://google.com][google]] or [[www.google.com]]
		      ;; langtool could finish checking before major mode prepare font face for all texts
		      (setq rlt nil))
		     (t
		      ;; inside source block?
		      (setq b (re-search-backward begin-regexp nil t))
		      (if b (setq e (re-search-forward end-regexp nil t)))
		      (if (and b e (< start e)) (setq rlt nil)))))
		  ;; (if rlt (message "start=%s end=%s ff=%s" start end ff))
		  rlt)))))

  ;; only check text inside comment or string when coding

  (eval-after-load 'prog-mode
    '(progn
       (unless (featurep 'flyspell) (require 'flyspell))
       (setq langtool-generic-check-predicate
	     '(lambda (start end)
		(let* ((f (get-text-property start 'face)))
		  (memq f flyspell-prog-text-faces)))))))


;;; SPELL CORRECTION

;; (1/3) hooks activation

(use-package flyspell
  :ensure nil
  :config
  (dolist (hook '(text-mode-hook))
    (add-hook hook (lambda () (flyspell-mode 1))))
  (dolist (hook '(change-log-mode-hook log-edit-mode-hook))
    (add-hook hook (lambda () (flyspell-mode -1))))
  (add-hook 'elisp-mode-hook
	    (lambda ()
	      (flyspell-prog-mode)))
  (add-hook 'python-mode-hook
	    (lambda ()
	      (flyspell-prog-mode))))


;; (2/3) dictionaries

(use-package ispell
  :ensure nil
  :config

  (defface ispell-alpha-num-choice-face
    '((t (:background "black" :foreground "red")))
    "Face for `ispell-alpha-num-choice-face`."
    :group 'ispell)

  (defface ispell-text-choice-face
    '((t (:background "black" :foreground "ForestGreen")))
    "Face for `ispell-text-choice-face`."
    :group 'ispell)

  (setq ispell-program-name "hunspell")

  ;; Default dictionary
  (setq	ispell-dictionary   "en_US,en_med_glut")

  ;; set list of available dictionaries
  ;; source: [[help:ispell-hunspell-dict-paths-alist]]
  ;; Hunspell dictionaty of English medical terms: en_md_glut 
  ;; source: https://github.com/Glutanimate/hunspell-en-med-glut
  (let ((hunspell-dir
	 (if (file-directory-p my-emacs-user-dir)
	   (expand-file-name
	    "../software/hunspell-1.3.2-3-w32-bin/share/hunspell/old-iso-8859-1"
	    user-emacs-directory)
	 (expand-file-name "~/Downloads/hunspell-1.3.2-3-w32-bin/share/hunspell"))))
    (setq ispell-hunspell-dict-paths-alist
	  `(("en_med_glut" ,(format "%s/en_med_glut.dic" hunspell-dir))
	    ("en_US" ,(format "%s/en_US.dic" hunspell-dir))
	    ("de_DE" ,(format "%s/de_DE.dic" hunspell-dir)))))

  (ispell-set-spellchecker-params)

  ;; use multiple dictionaries simultaneously
  (ispell-hunspell-add-multi-dic "en_US,en_med_glut")

  ;; FIXME hunspell do not correct properly
  ;; 11-dehydrocorticosterone
  )


;; syntax checking

;; check languages available and supported fot emacs+flycheck
;; source: https://www.flycheck.org/en/latest/languages.html#flycheck-languages

(use-package flycheck
  :ensure t
  ;; :init (global-flycheck-mode)
  :bind ("<f9>" . flycheck-mode)
  )


;; abbrev

;; (use-package abbrev
;;   :ensure nil
;;   :config
;;   (load (expand-file-name "elisp/my-abbrev.el"
;; 			  user-emacs-directory)))

;; dictionary to search words meaning or a buffer with dictionary support

(use-package dictionary
  :ensure t
  :bind
  (("C-c s" . dictionary-search)
   ("C-c m" . dictionary-match-words))
  ) 

;; user custom macros

(use-package macros
  :ensure nil
  :bind
  ("M-ñ M-i" . macro-org-doi-link-format)
  ("M-ñ M-c" . macro-taxonomy-cleansing)
  ("M-ñ M-d" . macro-german-date-to-english-timestamp)
  :config

  ;; macro for specific cleansing 

  (fset 'macro-taxonomy-cleansing
	[C-home ?\C-\M-% ?\\ ?\( ?\' ?\\ ?| ?\[ ?\[ ?\] ?\\ ?| ?\[ ?\] ?\] ?\\ ?| ?^ ?x ?  ?\\ ?\) return return ?! C-home ?\M-x ?s ?o ?r ?t ?- ?l ?i ?n ?e ?s return])

  ;; macro for convert german into english (standard) time stamp format
  
  (fset 'macro-german-date-to-english-timestamp
	(kmacro-lambda-form [C-home ?\C-\M-% ?\\ ?\( ?\[ ?0 ?- ?9 right ?\\ ?\{ ?2 right right right right ?\\ ?. ?\C-  C-left left left left left left left left left left ?\M-w C-right C-right C-right C-right ?\C-y ?\C-y left left left left left left backspace ?4 right right right right right right backspace backspace return up down ?< ?> left ?\\ ?3 ?- ?\\ ?2 ?- ?\\ ?1 return ?! C-home tab] 0 "%d"))
  
  ;; 
  (fset 'macro-org-doi-link-format
	(kmacro-lambda-form [?\C-u ?\C-y ?\M-l right delete ?\C-u left] 0 "%d"))
  )


;; avoid emacs to overwrite customization file

(use-package cus-edit
  :ensure nil
  :config
  (setq custom-file null-device))


;; set custom theme

(use-package verison-8-theme
  :ensure nil
  ;; :after custom
  :after faces
  :load-path "themes"
  :config    

  ;; Change cursor color according to mode; inspired by
  ;; http://www.emacswiki.org/emacs/ChangingCursorDynamically
  ;; Valid values for set-cursor-type are: t, nil, box, hollow
  ;; we can use bar & hbar, like this: (bar . WIDTH), (hbar. HEIGHT)

  (setq djcb-read-only-color       "white"
	djcb-read-only-cursor-type 'hollow
	;; djcb-overwrite-color       "red"
	djcb-overwrite-color (face-attribute 'font-lock-string-face :foreground)
	djcb-overwrite-cursor-type 'box
	;; djcb-normal-color          "turquoise1"
	djcb-normal-color (face-attribute 'cursor :background)
	djcb-normal-cursor-type    'box)
  
  (defun djcb-set-cursor-according-to-mode ()
    "change cursor color and type according to some minor modes."
    (cond
     (buffer-read-only
      (set-cursor-color djcb-read-only-color)
      (setq cursor-type djcb-read-only-cursor-type))
     (overwrite-mode
      (set-cursor-color djcb-overwrite-color)
      (setq cursor-type djcb-overwrite-cursor-type))
     (t 
      (set-cursor-color djcb-normal-color)
      (setq cursor-type djcb-normal-cursor-type))))
  (add-hook 'post-command-hook 'djcb-set-cursor-according-to-mode))


;; open package of custom functions

(use-package private
  :ensure nil
  :config
  (global-set-key (kbd "<s-f1>") 'bt))


;; open custom modes

(use-package scientificname-mode
  :ensure nil
  :bind ("C-<f11>" . scientificname-mode)) ;; key map= C-c C-x

(use-package frame
  :ensure nil
  :init

  ;; frame customizations: title format

  (setq frame-title-format
	(setq icon-title-format
	      (format 
	       "emacs-%s%s@%s : %%b"
	       emacs-major-version
	       emacs-minor-version
	       (if (equal system-type 'windows-nt) 'windows-nt 
		 (if (equal system-type 'gnu/linux) 'anarchy)))))

  ;; split window vertically

  (defun toggle-window-split ()
    (interactive)
    (if (= (count-windows) 2)
	(let* ((this-win-buffer (window-buffer))
	       (next-win-buffer (window-buffer (next-window)))
	       (this-win-edges (window-edges (selected-window)))
	       (next-win-edges (window-edges (next-window)))
	       (this-win-2nd (not (and (<= (car this-win-edges)
					   (car next-win-edges))
				       (<= (cadr this-win-edges)
					   (cadr next-win-edges)))))
	       (splitter
		(if (= (car this-win-edges)
		       (car (window-edges (next-window))))
		    'split-window-horizontally
		  'split-window-vertically)))
	  (delete-other-windows)
	  (let ((first-win (selected-window)))
	    (funcall splitter)
	    (if this-win-2nd (other-window 1))
	    (set-window-buffer (selected-window) this-win-buffer)
	    (set-window-buffer (next-window) next-win-buffer)
	    (select-window first-win)
	    (if this-win-2nd (other-window 1))))))

  ;; frame customizations: geometry and location 

  (let
      ((calculated-frame-height
  	(- (* (/ (cadddr (frame-monitor-workarea)) 3) 2) 50))
       (calculated-frame-width
  	(- (/ (caddr (frame-monitor-workarea)) 3)
	   (cdr (assoc 'scroll-bar-width (frame-parameters)))))
       (frame-position-list '())
       (positions (/ (caddr (frame-monitor-workarea)) 3)))
    
    (dotimes (i 3)
      (add-to-list
       'frame-position-list
       (+ (+ (* positions (expt i 1))) 
  	  (* (% 1 (expt i i)) (expt i (+ i 1))))
       t))

    (setq initial-frame-alist
  	  `((vertical-scroll-bars . nil)
	    (left-fringe . ,(cdr (assoc 'left-fringe (frame-parameters))))
	    (right-fringe . ,(cdr (assoc 'right-fringe (frame-parameters))))
	    (left . ,(elt frame-position-list 0))
  	    (top . 0)
  	    (height text-pixels . ,calculated-frame-height)
  	    (width text-pixels . ,calculated-frame-width)))

    (setq default-frame-alist
  	  `((vertical-scroll-bars . nil)
	    (left-fringe . ,(cdr (assoc 'left-fringe (frame-parameters))))
	    (right-fringe . ,(cdr (assoc 'right-fringe (frame-parameters))))
	    (left . ,(elt frame-position-list 1))
  	    (top . 0)
  	    (height text-pixels . ,calculated-frame-height)
  	    (width text-pixels . ,calculated-frame-width)))

    (defun modify-frame-location-upper-left () 
      (interactive)
      (modify-frame-parameters
       nil
       `((left . ,(elt frame-position-list 0))
  	 (top . 0)
  	 (height text-pixels . ,calculated-frame-height)
  	 (width text-pixels . ,calculated-frame-width))))

    (defun modify-frame-location-upper-middle () 
      (interactive)
      (modify-frame-parameters
       nil
       `((left . ,(elt frame-position-list 1))
  	 (top . 0)
  	 (height text-pixels . ,calculated-frame-height)
  	 (width text-pixels . ,calculated-frame-width))))

    (defun modify-frame-location-upper-right () 
      (interactive)
      (modify-frame-parameters
       nil
       `((left . ,(elt frame-position-list 2))
  	 (top . 0)
  	 (height text-pixels . ,calculated-frame-height)
  	 (width text-pixels . ,calculated-frame-width))))

    (defun modify-frame-location-lower-left () 
      (interactive)
      (modify-frame-parameters
       nil
       `((left . ,(elt frame-position-list 0))
  	 (top . ,(+ calculated-frame-height 50))
  	 (height text-pixels . ,(- (/ calculated-frame-height 2) 25))
  	 (width text-pixels . ,calculated-frame-width))))

    (defun modify-frame-location-lower-middle () 
      (interactive)
      (modify-frame-parameters
       nil
       `((left . ,(elt frame-position-list 1))
  	 (top . ,(+ calculated-frame-height 50))
  	 (height text-pixels . ,(- (/ calculated-frame-height 2) 25))
  	 (width text-pixels . ,calculated-frame-width))))

    (defun modify-frame-location-lower-right () 
      (interactive)
      (modify-frame-parameters
       nil
       `((left . ,(elt frame-position-list 2))
  	 (top . ,(+ calculated-frame-height 50))
  	 (height text-pixels . ,(- (/ calculated-frame-height 2) 25))
  	 (width text-pixels . ,calculated-frame-width)))))

  (defun new-frame-location-upper-right ()
    (interactive)
    (progn (select-frame (make-frame))
	   (modify-frame-location-upper-right)))
  
  :bind
  (("<C-f1>" . modify-frame-location-upper-left)
   ("<C-f2>" . modify-frame-location-upper-middle)
   ("<C-f3>" . modify-frame-location-upper-right)
   ("C-ñ <C-f1>" . modify-frame-location-lower-left)
   ("C-ñ <C-f2>" . modify-frame-location-lower-middle)
   ("C-ñ <C-f3>" . modify-frame-location-lower-right)
   ("C-x |" . toggle-window-split)
   ;; new frame in custom position
   ("C-x 5 3" .	new-frame-location-upper-right)))


;; remember cursor last location

(use-package saveplace
  :ensure nil
  :config
  (setq save-place-file 
	(expand-file-name "places" user-emacs-directory))
  (save-place-mode t))


;; ste cursor bookmark directory 

(use-package bookmark
  :ensure nil
  :config
  (setq bookmark-default-file
	(expand-file-name "bookmarks" user-emacs-directory)))


;; prefer utf-8 encoding for everything (windows-nt & gnu/linux)

(when (equal system-type 'windows-nt)
  (use-package "mule-cmds"
    :ensure nil
    :config
    (setq system-time-locale "C")
    (setq locale-coding-system 'utf-8) ;;cp1252
    (set-language-environment 'spanish)
    (set-default-coding-systems 'utf-8)
    (set-terminal-coding-system 'utf-8)
    (prefer-coding-system 'utf-8)
    (use-package mule
      :ensure nil
      :config
      (set-selection-coding-system 'utf-16-le))))

(when (equal system-type 'gnu/linux)
  (use-package mm-util
    :ensure nil
    :config
    (setq mm-coding-system-priorities '(utf-8)))
  (use-package "mule-cmds"
    :ensure nil
    :config
    (prefer-coding-system 'utf-8)
    (set-default-coding-systems 'utf-8)
    (use-package mule
      :ensure nil
      :config
      (set-keyboard-coding-system 'utf-8))))


;; fill paragraph customized commands

(use-package fill
  :ensure nil
  :init

  (defun unfill-paragraph (&optional region)
    "Takes a multi-line paragraph and makes it 
    into a single line of text."
    (interactive (progn (barf-if-buffer-read-only) '(t)))
    (let ((fill-column (point-max))
	  ;; This would override `fill-column' if it's an integer.
	  (emacs-lisp-docstring-fill-column t))
      (fill-paragraph nil region)))

  (defun duplicate-current-line-or-region (arg)
    "Duplicates the current line or region ARG times. 
    If there's no region, the current line will be duplicated. 
    However, if there's a region, all lines that region covers 
    will be duplicated."
    (interactive "p")
    (let (beg end (origin (point)))
      (if (and mark-active (> (point) (mark)))
	  (exchange-point-and-mark))
      (setq beg (line-beginning-position))
      (if mark-active
	  (exchange-point-and-mark))
      (setq end (line-end-position))
      (let ((region (buffer-substring-no-properties beg end)))
	(dotimes (i arg)
	  (goto-char end)
	  (newline)
	  (insert region)
	  (setq end (point)))
	(goto-char (+ origin (* (length region) arg) arg)))))

  (defun move-text-internal (arg)
    "move 'text' up/down"
    (cond
     ((and mark-active transient-mark-mode)
      (if (> (point) (mark))
	  (exchange-point-and-mark))
      (let ((column (current-column))
	    (text (delete-and-extract-region (point) (mark))))
	(forward-line arg)
	(move-to-column column t)
	(set-mark (point))
	(insert text)
	(exchange-point-and-mark)
	(setq deactivate-mark nil)))
     (t
      (beginning-of-line)
      (when (or (> arg 0) (not (bobp)))
	(forward-line)
	(when (or (< arg 0) (not (eobp)))
	  (transpose-lines arg))
	(forward-line -1)))))

  (defun move-text-down (arg)
    "Move region (transient-mark-mode active) or current line
	   arg lines down."
    (interactive "*p")
    (move-text-internal arg))

  (defun move-text-up (arg)
    "Move region (transient-mark-mode active) or current line
	   arg lines up."
    (interactive "*p")
    (move-text-internal (- arg)))

  :bind (("C-d" . duplicate-current-line-or-region)
	 ("<f5>" . move-text-up)
	 ("<f4>" . move-text-down)
	 ("M-ñ M-u" . unfill-paragraph)
	 ("M-ñ M-f" . fill-paragraph)
	 ("<C-f8>" . compare-windows)))

;;; Third party packages

;; essential: support for unicode in emacs

(use-package unicode-fonts
  :ensure t
  :config
  (unicode-fonts-setup))


;; speed unicode startup by persistent cache

(use-package persistent-soft
  :ensure t
  :config
  (persistent-soft-store 'hundred 100 "mydatastore")
  (persistent-soft-fetch 'hundred "mydatastore")    ; 100
  (persistent-soft-fetch 'thousand "mydatastore")   ; nil
  
  ;; quit and restart Emacs
  
  (persistent-soft-fetch 'hundred "mydatastore")    ; 100
  )

;; fill function improvement by filladapt
					; source http://elpa.gnu.org/packages/filladapt.html

(use-package filladapt
  :ensure t
  :config
  (setq-default filladapt-mode t)
  (add-hook 'text-mode-hook #'filladapt-mode)
  )


;; support fro Haskell

(use-package haskell-mode
  :ensure t)


;; support for R statistics, S-Plus, SAS, Stata and OpenBUGS/JAGS

(use-package ess
  :ensure t
  :init
  (require 'ess-site))


;; support for latex
;; source: https://emacs.stackexchange.com/questions/34189/emacs-setup-for-latex-after-use-package-verse

(use-package reftex
  :commands turn-on-reflex
  :config
  (setq reftex-plug-into-AUCTeX t))


;; source https://github.com/jwiegley/use-package/issues/379
(use-package tex
  :ensure auctex
  :config
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq-default TeX-master nil)
  ;; (add-to-list 'org-latex-packages-alist
  ;;              '("AUTO" "polyglossia" t ("xelatex" "lualatex")))
  )


;; Display hexagecimal color strings  with a background color

(use-package rainbow-mode
  :ensure t
  :config
  (add-hook 'prog-mode-hook 'rainbow-mode)
  (add-hook 'emacs-lisp-mode-hook 'rainbow-mode))


;; display delimiters in color

(use-package rainbow-delimiters
  :ensure t
  :config (rainbow-delimiters-mode)
  :hook ((emacs-lisp-mode . rainbow-delimiters-mode)
	 ;; (org-mode . rainbow-delimiters-mode)
	 (prog-mode . rainbow-delimiters-mode)))


;; display menu bar items in minibuffer: + S-TAB = recent files

(use-package lacarte                                
  :ensure nil
  :load-path "elisp"
  :bind (("ESC M-x" . lacarte-execute-menu-command) 
	 ("M-¿" . lacarte-execute-menu-command)))


;; show emacs keyshorcuts in minibuffer

(use-package which-key
  :ensure t
  :init
  (setq which-key-idle-delay 1)
  :config
  (which-key-mode))


;; edit emacs template (deprecated by yasnippet)

;; (use-package template
;;   :load-path "elisp")

(use-package smartparens-config
  :ensure smartparens
  :init 
  ;; activate smartparens
  (smartparens-global-mode)

  ;; toggle for sp on in all buffers
  (show-smartparens-global-mode t)

  ;; activate smartparens in minibuffer
  (add-hook 'minibuffer-setup-hook (lambda()(smartparens-mode 1)))

  ;; highlight enclosing pair of parens
  (setq sp-show-pair-from-inside -1)

  ;; org-mode: set special characters '' __ ~~ // == just for wrapping
  (sp-local-pair 'org-mode "'" nil :actions '(wrap))
  (sp-pair "_" "_" :actions '(wrap))
  (sp-pair "~" "~" :actions '(wrap))
  (sp-pair "/" "/" :actions '(wrap))
  (sp-pair "=" "=" :actions '(wrap))

  :bind
  (("C-1" . sp-backward-slurp-sexp) ; pull left delimiter lower level
   ("C-2" . sp-backward-barf-sexp)  ; push left delimiter upper level
   ("C-3" . sp-forward-barf-sexp)   ; pull right delimiter lower level
   ("C-4" . sp-forward-slurp-sexp)  ; push right delimiter upper level
   ("C-9" . sp-rewrap-sexp)         ; pull right delimiter lower level
   ("C-0" . sp-splice-sexp))        ; pull right delimiter lower level

  :custom-face
  (sp-show-pair-enclosing ((t (:foreground "violet"))))
  (sp-pair-overlay-face ((t (:foreground "black"))))
  (sp-show-pair-match-face ((t (:weight bold :foreground "black" :background "LightCyan1"))))
  (sp-pair-overlay-face ((t (:weight bold))))
  (sp-show-pair-match-content-face ((t (:inherit nil :weight bold))))
  (sp-show-pair-mismatch-face ((t (:weight bold :foreground "#2d2d2d" :background "#f2777a")))))

(use-package multiple-cursors 
  :ensure t
  :bind (("C-S-c" . mc/edit-lines)
	 ("<C-f4>" . mc/mark-next-like-this)
	 ("<C-f5>" . mc/mark-previous-like-this)
	 ("<C-f6>" . mc/mark-all-like-this))
  :init
  (progn 
    (set-face-attribute `region nil :foreground "white" :background "RoyalBlue2" :weight 'normal)
    ;; (set-face-attribute `cursor nil :background "red")
    ;; (setq-default cursor-type 'box);; options "box" "t" or "'hallow"
    (setq blink-cursor-blinks 0)
    (setq blink-cursor-interval 0.6)
    (blink-cursor-mode)))

(use-package phi-search
  :ensure t)

;; (use-package phi-search-mc
;; :ensure t)

;; search selected region in multiple browsers: engine-mode

(use-package engine-mode
  :ensure t
  :config
  (engine-mode t)
  (defengine amazon    "http://www.amazon.com/s/ref=nb_sb_noss?url=search-alias%3Daps&field-keywords=%s")
  (defengine dictionary
    "https://www.dictionary.com/browse/%s"
    :keybinding "D")
  (defengine duckduckgo
    "https://duckduckgo.com/?q=%s"
    :keybinding "d")
  (defengine github
    "https://github.com/search?ref=simplesearch&q=%s")
  (defengine google
    "http://www.google.com/search?ie=utf-8&oe=utf-8&q=%s"
    :keybinding "G")
  (defengine google-images "http://www.google.com/images?hl=en&source=hp&biw=1440&bih=795&gbv=2&aq=f&aqi=&aql=&oq=&q=%s")
  (defengine google-maps
    "http://maps.google.com/maps?q=%s"
    :docstring "Mappin' it up.")
  (defengine project-gutenberg
    "http://www.gutenberg.org/ebooks/search/?query=%s")
  (defengine rfcs
    "http://pretty-rfc.herokuapp.com/search?q=%s")
  (defengine stack-overflow
    "https://stackoverflow.com/search?q=%s")
  (defengine twitter
    "https://twitter.com/search?q=%s")
  (defengine wikipedia "https://www.wikipedia.org/search-redirect.php?language=en&go=Go&search=%s"
    :keybinding "w"
    :docstring "Searchin' the wikis.")
  (defengine wiktionary "https://www.wikipedia.org/search-redirect.php?family=wiktionary&language=en&go=Go&search=%s")
  (defengine wolfram-alpha
    "https://www.wolframalpha.com/input/?i=%s")
  (defengine youtube
    "http://www.youtube.com/results?aq=f&oq=&search_query=%s"
    :keybinding "y")
  (defengine pubmed
    "https://www.ncbi.nlm.nih.gov/pubmed/?term=%s"
    :keybinding "p")
  (defengine pubmed-genome
    "https://www.ncbi.nlm.nih.gov/genome/?term=%s"
    :keybinding "g")
  ;; (defengine pubmed-proteome
  ;; "https://www.ncbi.nlm.nih.gov/proteome/?term=%s"
  (defengine pubmed-proteome
    "https://www.ncbi.nlm.nih.gov/protein/?term=%s"
    :keybinding "P")
  ;; (defengine translation-english-spanish "https://www.apertium.org/index.eng.html?dir=eng-spa&q=%s#translation"
  (defengine translation-english-spanish "https://www.deepl.com/translator#en/es/%s%%0A"
    :keybinding "L")
  (defengine translation-google "https://translate.google.com/#view=home&op=translate&sl=en&tl=es&text=%s"
    :keybinding "t")
  (defengine translation-google-DE "https://translate.google.com/#view=home&op=translate&sl=de&tl=es&text=%s"
    :keybinding "T")
  (defengine synonyms-thesaurus "https://www.thesaurus.com/browse/%s?s=t"
    :keybinding "s")
  (defengine synonyms-ludwig "https://ludwig.guru/s/%s"
    :keybinding "S")
  (defengine theme-finder "https://www.opendesktop.org/%s"
    :keybinding "l")
  ;; (engine/set-keymap-prefix (kbd "M-ñ s")
  )

(use-package lorem-ipsum
  :ensure t
  :bind (("M-ñ l p" . lorem-ipsum-insert-paragraphs)
	 ("M-ñ l s" . lorem-ipsum-insert-sentences)
	 ("M-ñ l l" . lorem-ipsum-insert-list)))

;;; HTTP REST WEBSERVICES

(use-package restclient
  :ensure t
  :mode (("\\.rest\\'" . restclient-mode)))

;; # login
;; POST http://localhost:4000/sessions
;; {"username": "magnars", "password": "rockin"}

;; # GET all events
;; GET  http://localhost:4000/events

(use-package ob-restclient
  :ensure t)


;;; DATABASE MANAGEMENT

;; add emacs support for postgresql: emacsql-pgql 
;; source: https://github.com/ejmr/DotEmacs/blob/master/init.el

(use-package pg 
  :ensure t)

;; emacs sql support

(use-package emacsql
  :ensure t)

;; SQLite3 support

(use-package emacsql-sqlite
  :ensure t)

;; postgresql support

;; (use-package emacsql-psql
;;  :after emacsql)


;; http server config

(use-package impatient-mode
  :ensure t)


;; start http server for impatient mode (httpd-start))

;; (progn
;; ;; 1.- always
;; ;; (require 'impatient-mode)
;; ;; (add-hook 'html-mode-hook #'impatient-mode)

;; ;;2.- funtion to call impatient-mode and use that funtion as kooh method
;; (require 'impatient-mode)
;; (require 'simple-httpd)
;; (defun my-html-mode-hook ()
;;   "Starts the `simple-httpd' server if it is not already running, and turns
;; on `impatient-mode' for the current buffer."
;;   (unless (get-process "httpd")
;;     (message "starting httpd server...")
;;     (httpd-start))
;;   (impatient-mode))
;; (add-hook #'html-mode-hook #'my-html-mode-hook)
;; )


;; support for file format YAML

(use-package yaml-mode
  :ensure t)


;; emacs REPL customization  

(use-package comint                   
  :ensure nil
  :init
  (setq comint-scroll-to-bottom-on-input t)
  (setq comint-scroll-to-bottom-on-output t)
  (setq comint-move-point-for-output t))


;; show directory tree

(use-package neotree
  :ensure t
  :init
  (setq neo-theme (if (display-graphic-p) 'arrow 'arrow)) ;; icons arrow ascii nerd
  (setq-default neo-smart-open t)
  :bind ([f8] . neotree-toggle)
  :config 
  (use-package all-the-icons
    :ensure t
    :init
    ;; (when (not (file-exists-p (expand-file-name "../.local/share/fonts/all-the-icons.ttf" user-emacs-directory)))
    ;;   (command-execute 'all-the-icons-install-fonts))))
    (if (file-directory-p my-emacs-user-dir)
     (when (not (file-exists-p (expand-file-name "../.local/share/fonts/all-the-icons.ttf" user-emacs-directory)))
       (command-execute 'all-the-icons-install-fonts))
     (when (not (file-exists-p (expand-file-name "~/.local/share/fonts/all-the-icons.ttf" user-emacs-directory)))
       (command-execute 'all-the-icons-install-fonts))
     )))


;; package to improve the searching menu: helm

(use-package helm
  :ensure t
  :bind (("C-x b" . helm-buffers-list)
	 ("C-x r b" . helm-bookmarks)
	 ;; ("M-x" . helm-M-x)
	 ("M-y" . helm-show-kill-ring)
	 ;; ("C-x C-f" . helm-find-files)
	 )
  :init
  ;;  (require 'helm-config)
  ;;  (setq helm-ff-skip-boring-files t)

  ;;; don't breack if hide-comnt.el not exists
  ;; (load "hide-comnt") ;; deprecated
  (let* ((mydir "~/.emacs.d/elisp")
	 (myfile "hide-comnt.el")
	 (entire-path (expand-file-name myfile mydir)))
    (if (file-exists-p entire-path)
	;; open hide-comnt.el if exists
    	(load-file entire-path)
      ;; download hide-comnt.el if not exists
      (progn
	(require 'url)
	;; create required directory
	(if nil (file-directory-p mydir) (mkdir mydir t))
	;; download file
	(url-copy-file 
	 "https://www.emacswiki.org/emacs/download/hide-comnt.el"
	 entire-path
	 t))))
  (helm-mode)
  :custom-face
  (helm-source-header
   ((t (:family "Sans Serif"
		:height 1.3
		:weight bold
		:foreground "black"
		:background "MediumSpringGreen"))))
  (helm-selection
   ((t (:background "RoyalBlue"
		    :distant-foreground "black"))))
  :config
  (use-package helm-buffers
    :ensure nil
    :custom-face
    (helm-buffer-size
     ((t (:foreground "cyan1"))))
    (helm-buffer-process
     ((t (:foreground "cyan1")))) ;MediumSpringGreen
    (helm-non-file-buffer
     ((t (:inherit italic :weight bold)))) ;MediumSpringGreen
    )
  )


;; improve word search showing result highlight and lines matched

(use-package swiper
  ;; :ensure try
  :ensure t
  :config
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq enable-recursive-minibuffers t)
  ;; enable this if you want `swiper' to use it
  ;; (setq search-default-mode #'char-fold-to-regexp)
  (global-set-key (kbd "C-ñ s") 'swiper)
  (global-set-key (kbd "C-ñ r") 'swiper-backward)
  (global-set-key (kbd "C-c C-r") 'ivy-resume)
  ;; (global-set-key (kbd "<f6>") 'ivy-resume)
  (global-set-key (kbd "M-x") 'counsel-M-x)
  (global-set-key (kbd "C-x C-f") 'counsel-find-file)
  (global-set-key (kbd "<f7> f") 'counsel-describe-function)
  (global-set-key (kbd "<f7> v") 'counsel-describe-variable)
  (global-set-key (kbd "<f7> o") 'counsel-describe-symbol)
  (global-set-key (kbd "<f7> l") 'counsel-find-library)
  (global-set-key (kbd "<f7> i") 'counsel-info-lookup-symbol)
  (global-set-key (kbd "<f7> u") 'counsel-unicode-char)
  (global-set-key (kbd "C-c g") 'counsel-git)
  (global-set-key (kbd "C-c j") 'counsel-git-grep)
  (global-set-key (kbd "C-c k") 'counsel-ag)
  ;; (global-set-key (kbd "C-x l") 'counsel-locate)
  ;; (global-set-key (kbd "C-S-o") 'counsel-rhythmbox)
  ;; (define-key minibuffer-local-map (kbd "C-r") 'counsel-minibuffer-history)
  )


;; required by swiper

(use-package counsel
  :ensure t)


;; autocompletion: auto-complete

(use-package auto-complete
  :ensure t
  :config
  ;; don't break if not installed 
  (when (require 'auto-complete-config nil 'noerror) 
    (add-to-list 'ac-dictionary-directories 
		 (expand-file-name "ac-dict" user-emacs-directory))
    (setq ac-comphist-file
	  (expand-file-name "ac-comphist.dat" user-emacs-directory))
    (ac-config-default))
  (load "auto-complete-config"))


;; git emacs

(use-package magit
  :ensure t
  :config
  (setq magit-view-git-manual-method 'man)
  :bind ("C-x g" . magit-status))


;; emacs snippets

(use-package yasnippet
  :ensure t
  ;; :ensure yasnippet-snippets          ; use pre-build snippets collection
  :hook ((prog-mode . yas-minor-mode)
	 (org-mode . yas-minor-mode))
  :init
  ;; use custom snippets collection
  (setq yas-snippet-dirs `(,(expand-file-name "snippets"
					      user-emacs-directory)))
  (setq yas-indent-line 'none)
  :config 
  ;; (when (not (file-directory-p (expand-file-name "plugins/yasnippet" user-emacs-directory)))
  ;;   (shell-command-as-string "cd ~/.emacs.d/plugins | git clone --recursive https://github.com/joaotavora/yasnippet"))
  (yas-reload-all)
  ;; (yas-global-mode)
  ;; :bind (:map yas-minor-mode-map
  ;; 		("TAB" . nil)
  ;; 		("<tab>" . nil))
  :bind  ("<C-f12>" . yas-minor-mode)
  )

(use-package org-ref
  :ensure t
  :after org
  :init

  ;; Latex Export
  
  (setq org-latex-pdf-process '("latexmk -pdflatex='pdflatex -interaction nonstopmode' -pdf -bibtex -f %f"))

  ;; open pdf with system pdf viewer

  (setq bibtex-completion-pdf-open-function
	(lambda (fpath)
	  (start-process "open" "*open*" "open" fpath)))

  (setq reftex-default-bibliography
	(expand-file-name
	 "../documents/org/references.bib"
	 user-emacs-directory))
  (setq org-ref-default-bibliography
	(expand-file-name
	 "../documents/org/references.bib"
	 user-emacs-directory))
  (setq org-ref-pdf-directory
	(expand-file-name
	 "../documents/org/PDFs/"
	 user-emacs-directory))
  (setq org-ref-bibliography-notes
	(expand-file-name
	 "../documents/org/bibtex-notes/bibliography-notes.org"
	 user-emacs-directory))

  :config

  ;; increment scale in preview latex formulas

  ;; (set-default 'preview-scale-function 2)
  (setq org-format-latex-options
	(plist-put org-format-latex-options :scale 2))

  (use-package org
    ;; :ensure org-plus-contrib
    :defer 7
    :bind (("C-c a" . org-agenda)
	   ("C-c c" . org-capture)
	   ("C-c l" . org-store-link)
	   ("<f6>" . (lambda()(interactive)(insert "β"))))
    :hook 

    ;; org display inline images (require header=:results output graphics)

    ((org-babel-after-execute . org-display-inline-images)
     (org-mode . org-display-inline-images))

    :init

    ;; org global customization

    (setq org-directory
	  (expand-file-name "../documents/org" user-emacs-directory))
    (setq org-adapt-indentation nil) 
    (setq org-confirm-babel-evaluate nil)
    (setq org-confirm-elisp-link-function nil)
    ;; (setq org-hide-emphasis-markers t) ;; hide markers: // ** == 
    (setq org-tags-column -66) 

    ;; org babel customization

    (setq org-src-fontify-natively t) 
    ;; (setq org-src-preserve-indentation t) 
    ;; (setq org-src-window-setup 'current-window) ;; eval in new frame

    ;; open link new window 
    (setq org-link-frame-setup
	  '((vm . vm-visit-folder-other-frame)
	    (vm-imap . vm-visit-imap-folder-other-frame)
	    (gnus . org-gnus-no-new-news)
	    (file . find-file) ; open link new window  
	    ;; (file . find-file-other-window) ; open link new window  
	    ;; (file . find-file-other-frame)  ; open link new frame
	    (wl . wl-other-frame)))

      ;;; set path to org files
    (setq org-agenda-files
	  (expand-file-name "../documents/org/todo.org" user-emacs-directory))
    (setq org-default-notes-file
	  (expand-file-name "../documents/org/notes.org" user-emacs-directory))
    (setq org-clock-persist 'history)
    (setq org-clock-persist-file
	  (expand-file-name "../config/org-clock-save.org" user-emacs-directory))
    (setq mc/list-file
	  (expand-file-name "../config/.mc-lists.el" user-emacs-directory))

    ;; open files by default or custom application:

    (setq org-file-apps
	  '(("\\.docx\\'" . default)
	    ("\\.odt\\'" . "libreoffice %s")
	    ("\\.xlsx\\'" . default)
	    ("\\.mm\\'" . default)
	    ("\\.x?html?\\'" . default)
	    ;; ("\\.x?html\\'" . "firefox %s")
	    ;; ("\\?:xhtml\\|html\\)\\'" . "chromium %s")
	    ;; ("\\.pdf\\'" . default)
	    ("\\.pdf\\'" . "okular %s")
	    (auto-mode . emacs)))

    ;; org custom templates

    (setq org-structure-template-alist
	  '(("n" . "notes")
	    ("a" . "export ascii")
	    ("C" . "center")
	    ("c" . "comment")
	    ("x" . "example")
	    ("h" . "export html")
	    ("l" . "export latex")
	    ("Q" . "quote")
	    ("q" . "src sql :session sql-postgres :engine postgresql :dbhost 127.0.0.1 :dbuser postgres :database test :results verbatim")
	    ("0" . "src")
	    ("e" . "src emacs-lisp")
	    ("E" . "src emacs-lisp :postamble ;(check-parens) :results silent :shebang #!emacs --script")
	    ("d" . "src ditaa :file image/ditaa-image.png")
	    ("p" . "src python :results output drawer :wrap src python :preamble (venv-workon \"myenv\")")
	    ("P" . "src python :session project :results output :preamble (venv-workon \"python381checker\") :postamble (org-pychecker) :shebang #!/bin/python")
	    ("m" . "src python :preamble \"# -*- coding: utf-8 -*-\" :session project :results output verbatim")
	    ("b" . "src bash :results verbatim")
	    ("B" . "src bash :session project :results verbatim silent :shebang #!/bin/bash")
	    ("s" . "src shell :results verbatim")
	    ("S" . "src shell :session project :results verbatim silent")
	    ("t" . "src translate :src de :dest es,en")
	    ("v" . "verse")))

    (add-to-list 'org-structure-template-alist '("r" . "src R"))
    (add-to-list 'org-structure-template-alist '("T" . "src sh :term t :results verbatim"))

    ;; add support for term in org babel (source:sacha chua, 2020-09-20)

    (defadvice org-babel-execute:bash (around sacha activate)
      (if (assoc-default :term (ad-get-arg 1) nil)
	  (let ((buffer (make-term "babel" "/bin/bash")))
	    (with-current-buffer buffer
	      (insert (org-babel-expand-body:generic
		       body params (org-babel-variable-assignments:sh params)))
	      (term-send-input))
	    (pop-to-buffer buffer))
	ad-do-it))

    
    :config

    ;; Customizing Annotated Bibliography in Org habilitating shift to
    ;; change "bibtex header/export tag/org TODO"

    (load-file
     (expand-file-name "elisp/custom-org.el" user-emacs-directory))

    ;; insert csv file content as org table

    (defun csv-to-table (file sep)
      (let ((org-table-convert-region-max-lines 2000)
	    (with-temp-buffer
	      (erase-buffer)
	      (insert-file file)
	      (org-table-convert-region (point-min) (point-max) sep)
	      (buffer-string)))))

    ;; browse pmid

    (defun raom-org-link--open-pmid (path)
      "open \"pmid\" type link
/PATH/ is the path to search for, as a string."
      (browse-url-firefox (concat "https://pubmed.ncbi.nlm.nih.gov/" path)))
    
    (org-link-set-parameters "pmid" :follow #'raom-org-link--open-pmid)

    ;; browse doi by scihub and tor

    (setq raom-doi-browser-url "https://sci-hub.tf/")

    (defun raom-org-link--open-doi (path)
      "open \"doi\" type link in adequate browser `raom-doi-browser-url'
/PATH/ is the path to search for, as a string."
      (async-shell-command (concat "sh -c '\"/home/angel/.local/share/torbrowser/tbb/x86_64/tor-browser_en-US/Browser/start-tor-browser\" " (concat raom-doi-browser-url org-link-doi-server-url path) "'")))

    (org-link-set-parameters "doi" :follow #'raom-org-link--open-doi)


    ;; set org block color by programming language

    (use-package org-src
      :ensure nil
      :init
      (setq org-src-window-setup 'current-window)
      (setq org-src-preserve-indentation t)
      ;; added latex support for xelatex
      (add-to-list 'org-latex-packages-alist
		   '("AUTO" "babel" t ("pdflatex")))
      ;; (add-to-list 'org-latex-packages-alist
      ;; 	     '("AUTO" "fontspec" t ("xelatex")))
      (add-to-list 'org-latex-packages-alist
		   '("AUTO" "polyglossia" t ("xelatex" "lualatex"))))

    
    ;; open org-pycheker.el (customized)
    
    (use-package org-pychecker
      :defer t
      :load-path "elisp"
      :ensure nil)

    
    ;; open org-ref-pubmed.el (customized 2020-08-12)
    
    (use-package org-ref-pubmed
      :load-path "elisp"
      :ensure nil)

    
    ;; open pubmed2bib.el (customized 2020-08-20)
    
    (use-package pubmed2bib
      :load-path "elisp"
      :ensure nil)

    ;; org Diagrams

    (use-package ob-ditaa
      :ensure nil
      :config
      (setq org-ditaa-jar-path
	    (expand-file-name
	     "../download/ditaa0_9.jar"
	     user-emacs-directory)))

    
    ;; source: https://github.com/abrochard/emacs-config/blob/master/configuration.org

    (use-package plantuml-mode
      :ensure t)

    
    ;; perl support

    (require 'ob-perl)


    ;; org load babel languages
    
    (org-babel-do-load-languages
     'org-babel-load-languages
     '(
       ;; (clojure    . t)
       (C          . t) ;; C, C++
       (ditaa      . t)
       (dot        . t) ;; graphviz-dot-mode
       (emacs-lisp . t)
       (latex      . t)
       (js         . t)
       ;; (sh         . t)
       ;; (prolog     . t)
       (org        . t)
       (python     . t)
       (R          . t)
       (shell      . t)
       (sql        . t)
       (sqlite     . t)))

    ;; export org documents by pandoc

    (use-package ox-pandoc
      :ensure t
      :init 
      (setq org-pandoc-menu-entry  
	    '((?m "as md." org-pandoc-export-as-markdown)
	      (?M "to md and open." org-pandoc-export-to-markdown-and-open)
	      (?x "to docx." org-pandoc-export-to-docx)
	      (?X "to docx and open." org-pandoc-export-to-docx-and-open)
	      (?e "to epub." org-pandoc-export-to-epub)
	      (?E "to epub and open." org-pandoc-export-to-epub-and-open)
	      (?3 "to epub3." org-pandoc-export-to-epub3)
	      (?£ "to epub3 and open." org-pandoc-export-to-epub3-and-open)
	      (?j "as json." org-pandoc-export-as-json)
	      (?J "to json and open." org-pandoc-export-to-json-and-open)
	      (?r "as rst." org-pandoc-export-as-rst)
	      (?R "to rst and open." org-pandoc-export-to-rst-and-open)
	      (?t "to texi (overwrite exist file)." org-texinfo-export-to-texinfo)
	      (?T "to info." org-texinfo-export-to-info))))

    ;; Journal
    ;; source: https://github.com/bastibe/org-journal
    
    (use-package org-journal
      :ensure t
      :bind ("M-ñ j" . org-journal-new-entry)
      ;; :defer t
      ;; :init
      ;; ;; Change default prefix key; needs to be set before loading org-journal
      ;; (setq org-journal-prefix-key "M-ñ j ")
      :config
      ;; (setq org-journal-file-type 'monthly) ;; posible values daily/monthly/yearly
      (setq org-journal-dir (expand-file-name "../documents/org/journal/" user-emacs-directory)
            org-journal-date-format "%A, %d/%m/%y"))))

;; --- end org-ref


(use-package gnuplot
  :ensure t)


(use-package gnuplot-mode
  :ensure t)


;; custom pubmed config

(load-file
 (expand-file-name "elisp/custom-pubmed-config.el" user-emacs-directory))

(use-package ace-jump-mode
  :ensure t
  :bind ("C-z" . ace-jump-mode))

;; metatrader support

(use-package mql-mode
  :ensure nil)

;;;PYTHON SUPPORT

;; pyenv (support for multiple python versions)

(use-package pyenv-mode
  :ensure t)

;; virtualwrapper (support for python virtual environments)

(use-package virtualenvwrapper
  :ensure t
  :init
  ;; virtualenvwrapper default location (`~/.virtualenvs`)
  (when (string-equal system-type 'windows-nt)
    (setq venv-location "c:/Users/Ricardo/Envs"))
  (when (string-equal system-type 'gnu/linux)
    (setq venv-location (format "/home/%s/.virtualenvs" (getenv "USER"))))
  (setq-default python-indent-offset 2) ;4 (deprecated 2021-01-21)
  ;; set python guess indent
  (setq python-indent-guess-indent-offset t)
  ;; silence the warning of python guess indent
  (setq python-indent-guess-indent-offset-verbose nil)
  ;; if you want interactive shell support
  (venv-initialize-interactive-shells)
  ;; if you want eshell support
  (venv-initialize-eshell)
  (setq python-shell-completion-native-enable nil))


;; jedi (python auto-completiom)

(use-package jedi-core
  :ensure t
  :config
  (setq python-environment-directory "/home/angel/.virtualenvs"))


(use-package jedi
  :ensure t
  :hook (python-mode . jedi:setup)
  :config
  (setq jedi:complete-on-dot t))

;; csharp support

(use-package csharp-mode
  :ensure t)

;; scharp edition

(use-package omnisharp
  :ensure t
  :config
  (add-hook 'csharp-mode-hook #'omnisharp-mode)
  (add-hook 'csharp-mode-hook #'flycheck-mode)
  )


;; php support

(use-package php-mode
  :ensure t)

;; custom scratch message

(load-file
 (expand-file-name "elisp/custom-scratch-message.el" user-emacs-directory))


;; cygwin shell support for windows

(load-file
 (expand-file-name "elisp/cygwin-windows.el" user-emacs-directory))
