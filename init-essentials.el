;; init-essentials.el -- Emacs init file -*- lexical-binding: t -*-
;;
;;;; ====================== HEADER =========================
;;
;; Title: Emacs Init File with Essential Customization
;; Author: Ricardo Orbegozo
;; Created: 2020-04-13
;; Updated: 2022-10-14
;;
;;;; Code:

;;;; ================ Accelerate Emacs Startup =============

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

;;;; =============== EMACS PACKAGE MANAGMENT ===============

;;;~ Avoid warning about deprecated package cl

(setq byte-compile-warnings '(cl-functions))
;;;~ Other codelines related
;; (with-no-warnings (require 'cl))
;; (eval-when-compile (require 'cl))

;;;~ package setup

(require 'package)

(add-to-list 'package-archives 
	     '("melpa" . "http://melpa.org/packages/"))
(add-to-list 'package-archives 
	     '("org" . "https://orgmode.org/elpa/"))

(setq package-enable-at-startup nil)
(package-initialize)


;;;~ set package configuration using "use-package"

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-and-compile
  (setq use-package-always-ensure t
	use-package-expand-minimally t
	;;;~ record how many packages have been loaded by use-package
	use-package-compute-statistics t)
  ;;;~ show how many packages have been loaded by use-package
  ;; (add-hook 'emacs-startup-hook 'use-package-report)
  )

;;;; =================== EMACS SETTINGS ====================

;;;; (1/3) SETTINGS WITHOUT CORRESPONDING PACKAGES ---------

  ;;;~ Emacs basic customizations: variables, toolbar, messages, etc 

  (use-package emacs
    :config

    ;;;~ declare custom function to show file name and path
    
    (defun show-file-name ()
      "Show the full path file name in the minibuffer."
      (interactive)
      (if (equal current-prefix-arg nil) ; no C-u
	  ;; then
	  (message (buffer-file-name))
	;; else
	(insert (buffer-file-name))))
    ;; (global-set-key [C-f1] 'show-file-name) ; deprecated

    ;;;~ don't show "C-g" prompt

    ;; (setq ring-bell-function 'ignore)
    ;; (setq visible-bell nil)

    ;;;~ set private variables: default-directory, user-emacs-directory

    ;; (load-file "~/.emacs.d/init-private--variables.el")


    ;;;~ show line numbers in: programming & text mode

    (add-hook 'prog-mode-hook 'display-line-numbers-mode)
    (add-hook 'text-mode-hook 'display-line-numbers-mode)

    ;;;~ basic emacs configuration

    (tool-bar-mode -1)                           ; don't show tool-bar
    (fset 'yes-or-no-p 'y-or-n-p)                ; simplify questions
    (put 'narrow-to-region 'disabled nil)        ; disable query
    ;; (setq-default line-spacing 2)             ; default line space
    (savehist-mode 1)			       ; save minibuffer history
    (setq frame-resize-pixelwise t)              ; resize frames by pixels

    ;;;~ startup emacs config

    (setq inhibit-startup-screen t)

    ;; (setq initial-scratch-message 'nil)
    (setq initial-scratch-message ";; This buffer is for text that is not saved, and for Lisp evaluation.
;; To create a file, visit it with \\[find-file] and enter text in its buffer.

")
    (setq auto-save-list-file-prefix
	  (expand-file-name
	   "../auto-save-list/.saves-" package-user-dir))

    :bind (("C-ñ 1" . show-file-name)	       ; show file name path
	   ("C-ñ ," . (lambda()(interactive)(insert "<"))); insert "<"
	   ("C-ñ ." . (lambda()(interactive)(insert ">"))); insert ">"
	   ("<f1>"  . call-last-kbd-macro)       ; kbd for emacs macro
	   ("C-c d" . insert-date)               ; insert date HH:MM:SS
	   ("<f12>" . display-line-numbers-mode)); show line numbers
    )

;;;; (2/3) BUILTIN PACKAGES ---------------------------------

;;;~ theme

(use-package custom
  :ensure nil
  :config
  ;; fix custom theme enable at startup emacs >26.3
  (if (version<= "26.3"  emacs-version)
      (setq custom--inhibit-theme-enable nil))
  ;; theme
  (load-theme 'wombat)
  (custom-theme-set-faces

   ;;;~ native theme

   'wombat

   ;;;~ cursor color

   '(cursor ((t (:background "LightSkyBlue"))))

   ;;;~ org
   ;;;~ org babel blocks

   '(org-block ((t (:background "gray10"))))
   '(org-block-begin-line
     ((t (:inherit org-block :foreground "gray70" :background "gray10"))))
     ;; ((t (:foreground "khaki" :background "gray10"))))
     ;; ((t (:foreground "gray40" :background "gray10"))))
   '(org-block-end-line
     ((t (:inherit org-block-begin-line))))
     ;; ((t (:foreground "gray40" :background "gray10"))))
   '(org-level-1
     ((t (:inherit shadow
	  :family "Dejavu Sans Mono"
	  :height 160 :weight normal))))
	  ;; :height 160 :weight bold :foreground "PaleTurquoise1"))))
     ;; ((t (:height 110 :weight semi-bold :foreground "khaki"))))
   '(org-level-2
     ((t (:inherit shadow
	  :family "Dejavu Sans Mono"
	  :height 140 :weight normal))))
     ;; ((t (:height 110 :weight semi-bold :foreground "sky blue"))))
   '(org-level-3
     ((t (:family "Dejavu Sans Mono"
	  :height 130 :weight normal :foreground "LightCyan3"))))
	  ;; :height 120 :weight semi-bold :foreground "gray90"))))
     ;; ((t (:height 110 :weight semi-bold :foreground "#e5786d"))))
   ;;   ((t (:extend nil :inherit outline-1))))

   ;;;~ org header tags (date, author, etc)

   ;; '(shadow ((t (:foreground "gray70"))))
   ;; '(org-document-info-keyword ((t (:inherit shadow))))
   '(org-document-info-keyword ((t (:inherit shadow))))

   ;;;~ #+PROPERTY:
   ;;;~ #+RESULTS:
   '(org-meta-line
     ((t (:inherit shadow :background "gray10"))))
   '(org-todo
     ((t (:weight bold :foreground "orange red"))))
   ;; '(org-level-2
   ;;   ((t (:extend nil :inherit outline-2))))
   ;; '(org-level-3
   ;;   ((t (:extend nil :inherit outline-3 :foreground "#Cae682"))))
   ;; '(outline-1
   ;;   ((t (:inherit font-lock-function-name-face))))
   ;; '(outline-2
   ;;   ((t (:inherit font-lock-variable-name-face))))
   ;; '(font-lock-function-name-face
   ;;   ((t (:foreground "#cae682"))))
   '(font-lock-variable-name-face
     ((t (:foreground "khaki"))))
   ;; '(outline-3
   ;;   ((t (:extend nil :inherit font-lock-keyword-face))))
   '(font-lock-keyword-face
     ;; ((t (:weight semi-bold :foreground "#8ac6f2"))));:weight bold
     ((t (:weight normal :foreground "sky blue"))));:weight bold
   ;; '(font-lock-dock-face
   ;;   ((t (:inherit font-lock-keyword-face))))
   ;; '(font-lock-keyword-face
   ;;   ((t (:inherit font-lock-string-face))))
   '(font-lock-string-face
     ((t (:foreground "PaleGreen")))); tstd MediumSeaGreen Ori #95e454
   ;;;~ comments
   '(font-lock-comment-face ((t (:foreground "gray60")))); tst
   ;; tstd CadetBlue4 LightBlue4 ori #99968b
   ;; '(font-lock-constant-face
   ;;   ((t (:weight semi-bold :foreground "VioletRed2"))))
     ;; ((T (:Foreground "medium sea green"))))
   ); end custom-theme-set-faces
  ); end custom

;;;~ update file changes

(use-package autorevert
  :ensure nil
  :config
  (global-auto-revert-mode 1))

;;;~ delete selected region such as MS-Word (word, etc)

(use-package delsel
  :ensure nil
  :config
  (delete-selection-mode 1)
  )

;;;~ backup configuration (source: catchestocatches.com)

(use-package files
  :ensure nil
  :config
  (setq confirm-kill-processes nil)
  (setq backup-directory-alist
	`(("." . ,(expand-file-name ".saves" user-emacs-directory))))
  (setq
   backup-by-copying t         ; don't clobber symlinks
   kept-new-versions 50        ; keep 20 latest versions
   kept-old-versions 200       ; don't bother with old versions
   delete-old-versions t       ; don't ask about deleting old versions
   version-control t           ; number backups
   vc-make-backup-files t))    ; backup version controlled files

;;;~ enable list of opened recent files

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

;;;~ display line mode with line & column numbers

(use-package simple
  :ensure nil
  :config
  (column-number-mode 1)       ; display column number in modeline 
  (line-number-mode 1)         ; display number in modeline
  (global-visual-line-mode 1)  ; wrap lines
  :bind
  (
  ;;;~ clone indirec buffer (inspired by psychology PhD student)
   ("C-x 5 c" . clone-indirect-buffer-other-frame)
   ("C-x O" . (lambda ()(interactive)(other-window -1)))
   ("C-x 5 o" . (lambda ()(interactive)(other-frame -1)))
   ("C-x 5 O" . other-frame))
  )

;;;~ unset emacs predefined key bindings 

(use-package bind-key
  :ensure nil
  :config
  (dolist (key '("\C-z"        ; minimize frame
		 "\M-q"        ; fill-paragraph
		 "\C-d"	       ; delete-char
		 [?\C-\.]))    ; flyspell-auto-correct-word -> "C-M-i"

    (global-unset-key key)     ; is also exists "local-unset-key"
    )
  ;; (unbind-key "C-." flyspell-mode-map)
  (global-set-key (kbd "C-S-d") 'delete-char)
  (global-set-key (kbd "<XF86Eject>") 'delete-char)
  (global-set-key (kbd "<f6>") '(lambda()(interactive)(insert "β")))
  )

;;;~ custom user macros

(use-package macros
  :ensure nil
  :bind
  ("M-ñ M-c" . macro-taxonomy-cleansing)
  :config

  ;;;~ macro for specific cleansing 

  (fset 'macro-taxonomy-cleansing
	[C-home ?\C-\M-% ?\\ ?\( ?\' ?\\ ?| ?\[ ?\[ ?\] ?\\ ?| ?\[ ?\] ?\] ?\\ ?| ?^ ?x ?  ?\\ ?\) return return ?! C-home ?\M-x ?s ?o ?r ?t ?- ?l ?i ?n ?e ?s return])

  )

;;;~ avoid emacs to overwrite customization file

(use-package cus-edit
  :ensure nil
  :config
  (setq custom-file null-device)
  )

;;;~ frame customizations (title, cursor, location and font)

(use-package frame
  :ensure nil
  :init

  ;;;~ custom title format

  (setq frame-title-format
	(setq icon-title-format
	      (format 
	       "emacs-%s%s@%s : %%b"
	       emacs-major-version
	       emacs-minor-version
	       (if (equal system-type 'windows-nt) 'windows-nt 
		 (if (equal system-type 'gnu/linux) 'anarchy)))))

  ;;;~ split window vertically

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

  ;;;~ frame geometry and location 

  (let*
      ((calculated-frame-height
  	(- (* (/ (cadddr (frame-monitor-workarea)) 3) 2) 50))
       (calculated-frame-width
  	(- (/ (caddr (frame-monitor-workarea)) 3)
	   (cdr (assoc 'scroll-bar-width (frame-parameters)))))
       (frame-position-list '())
       (positions (/ (caddr (frame-monitor-workarea)) 3))
       (wm--info (shell-command-to-string "wmctrl -m"))
       (wm--detected (and (string-match "^Name: \\(.*\\)" wm--info)
			  (print (match-string 1 wm--info)))))
    
    (dotimes (i 3)
      (add-to-list
       'frame-position-list
       (if (equal wm--detected "Xfwm4")
	   ;;;~ xfce wm require complex calculation
	   (+ (+ (* positions (expt i 1))) 
	      (* (% 1 (expt i i)) (expt i (+ i 1))))
	 ;;;~ the other window managers do not require this
	 (+ (* positions (expt i 1)))
	 )
       t))

    (setq initial-frame-alist
  	  `((font . "Ubuntu Mono-11")
	    (vertical-scroll-bars . nil)
	    (left-fringe . ,(cdr (assoc 'left-fringe (frame-parameters))))
	    (right-fringe . ,(cdr (assoc 'right-fringe (frame-parameters))))
	    (left . ,(elt frame-position-list 0))
  	    (top . 0)
  	    (height text-pixels . ,calculated-frame-height)
  	    (width text-pixels . ,calculated-frame-width)))

    (setq default-frame-alist
  	  `((font . "Ubuntu Mono-11")
	    (vertical-scroll-bars . nil)
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

  (defun fill-screen-with-frames ()
    (interactive)
    ;; Fill the upper row with frames:
    ;;  * locating the original frame to the left
    (modify-frame-location-upper-left)
    ;;  * and making new frames in the middle and the right
    (let* ((location-list
	    '(modify-frame-location-upper-middle
	      modify-frame-location-upper-right
	      modify-frame-location-lower-left
	      modify-frame-location-lower-middle
	      modify-frame-location-lower-right)))
      (dolist (frame-location location-list)
	(make-frame)
	(other-frame -1)
	(funcall frame-location))))

  :config

  ;;;~ Cursor Color
  
  ;; (set-cursor-color "SpringGreen")

  ;;;~ Change Cursor Color According To Mode

  ;;;~  inspired by:
  ;;;~   http://www.emacswiki.org/emacs/ChangingCursorDynamically
  ;;;~   Valid values for set-cursor-type are: t, nil, box, hollow
  ;;;~   we can use bar & hbar, like this: (bar . WIDTH), (hbar. HEIGHT)

  (setq cursor--read-only-color       "white"
	cursor--read-only-cursor-type 'hollow
	;; cursor--overwrite-color       "red"
	cursor--overwrite-color
	(face-attribute 'font-lock-string-face :foreground)
	cursor--overwrite-cursor-type 'box
	;; cursor--normal-color          "turquoise1"
	cursor--normal-color (face-attribute 'cursor :background)
	cursor--normal-cursor-type    'box)
  
  (defun cursor--set-cursor-according-to-mode ()
    "change cursor color and type according to some minor modes."
    (cond
     (buffer-read-only
      (set-cursor-color cursor--read-only-color)
      (setq cursor-type cursor--read-only-cursor-type))
     (overwrite-mode
      (set-cursor-color cursor--overwrite-color)
      (setq cursor-type cursor--overwrite-cursor-type))
     (t 
      (set-cursor-color cursor--normal-color)
      (setq cursor-type cursor--normal-cursor-type))))

  (add-hook 'post-command-hook 'cursor--set-cursor-according-to-mode)
  
  :bind
  (("<C-f1>" . modify-frame-location-upper-left)
   ("<C-f2>" . modify-frame-location-upper-middle)
   ("<C-f3>" . modify-frame-location-upper-right)
   ("C-ñ <C-f1>" . modify-frame-location-lower-left)
   ("C-ñ <C-f2>" . modify-frame-location-lower-middle)
   ("C-ñ <C-f3>" . modify-frame-location-lower-right)
   ("C-ñ <C-f4>" . fill-screen-with-frames)
   ("C-x |" . toggle-window-split)

   ;;;~ new frame in custom position

   ("C-x 5 3" .	new-frame-location-upper-right))
  )

;;;~ remember cursor last location

(use-package saveplace
  :ensure nil
  :config
  (setq save-place-file 
	(expand-file-name "places" user-emacs-directory))
  (save-place-mode t)
  )

;;;~ set cursor bookmark directory 

(use-package bookmark
  :ensure nil
  :config
  (setq bookmark-default-file
	(expand-file-name "bookmarks" user-emacs-directory))
  )

;;;~ fill paragraph customized commands

(use-package fill
  :ensure nil
  :init

  (defun unfill-paragraph (&optional region)
    "Takes a multi-line paragraph and makes it 
    into a single line of text."
    (interactive (progn (barf-if-buffer-read-only) '(t)))
    (let ((fill-column (point-max))
	  ;;;~ This would override `fill-column' if it's an integer.
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
	 ("<C-f8>" . compare-windows))
  )

;;;; (3/3) THIRD PARTY PACKAGES ----------------------------

;;;~ jump inside text

(use-package ace-jump-mode
  :ensure t
  :bind ("C-z" . ace-jump-mode)
  )

;;;~ Display hexagecimal color strings  with a background color

(use-package rainbow-mode
  :ensure t
  :config
  (add-hook 'prog-mode-hook 'rainbow-mode)
  (add-hook 'emacs-lisp-mode-hook 'rainbow-mode))

;;;~ display delimiters in color

(use-package rainbow-delimiters
  :ensure t
  :config (rainbow-delimiters-mode)
  :hook ((emacs-lisp-mode . rainbow-delimiters-mode)
	 ;; (org-mode . rainbow-delimiters-mode)
	 (prog-mode . rainbow-delimiters-mode)))


(use-package smartparens-config
  :ensure smartparens
  :init
  
  ;;;~ activate smartparens

  (smartparens-global-mode)

  ;;;~ toggle for sp on in all buffers

  (show-smartparens-global-mode t)

  ;;;~ activate smartparens in minibuffer

  (add-hook 'minibuffer-setup-hook
	    #'(lambda()(smartparens-mode 1)))

  ;;;~ highlight enclosing pair of parens

  (setq sp-show-pair-from-inside -1)

  ;;;~ org-mode: set special characters '' __ ~~ // == just for wrapping

  (sp-local-pair 'org-mode "'" nil :actions '(wrap))
  (sp-pair "_" "_" :actions '(wrap))
  (sp-pair "~" "~" :actions '(wrap))
  (sp-pair "/" "/" :actions '(wrap))
  (sp-pair "=" "=" :actions '(wrap))

  :bind
  (("C-1" . sp-backward-slurp-sexp) ; pull left  delimiter lower level
   ("C-2" . sp-backward-barf-sexp)  ; push left  delimiter upper level
   ("C-3" . sp-forward-barf-sexp)   ; pull right delimiter lower level
   ("C-4" . sp-forward-slurp-sexp)  ; push right delimiter upper level
   ("C-9" . sp-rewrap-sexp)         ; pull right delimiter lower level
   ("C-0" . sp-splice-sexp))        ; pull right delimiter lower level

  :custom-face
  (sp-show-pair-enclosing
   ((t (:foreground "violet"))))
  (sp-pair-overlay-face
   ((t (:foreground "black"))))
  (sp-show-pair-match-face
   ((t (:weight bold :foreground "black" :background "LightCyan1"))))
  (sp-pair-overlay-face
   ((t (:weight bold))))
  (sp-show-pair-match-content-face
   ((t (:inherit nil :weight bold))))
  (sp-show-pair-mismatch-face
   ((t (:weight bold :foreground "#2d2d2d" :background "#f2777a"))))
  )

(use-package multiple-cursors 
  :ensure t
  :bind
  (("C-S-c" . mc/edit-lines)
   ("<C-f4>" . mc/mark-next-like-this)
   ("<C-f5>" . mc/mark-previous-like-this)
   ("<C-f6>" . mc/mark-all-like-this))
  :init
  (progn 
    (set-face-attribute
     `region nil
     :foreground "white"
     :background "RoyalBlue2"
     :weight 'normal)
    ;; (set-face-attribute `cursor nil :background "red")
    ;; (setq-default cursor-type 'box);; options "box" "t" or "'hallow"
    (setq blink-cursor-blinks 0)
    (setq blink-cursor-interval 0.6)
    (blink-cursor-mode))
  :config
  (use-package phi-search
    :ensure t)
  (use-package phi-search-mc
    :ensure t)
  )

;;;~ show emacs keyshorcuts in minibuffer

(use-package which-key
  :ensure t
  :init
  (setq which-key-idle-delay 1)
  :config
  (which-key-mode))

;;;~ search selected region in multiple browsers: engine-mode

(use-package engine-mode
  :ensure t
  :config

  ;;;~ Activate Minor Mode
  
  (engine-mode t)

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
  (defengine youtube
    "http://www.youtube.com/results?aq=f&oq=&search_query=%s"
    :keybinding "y")
  (defengine pubmed
    "https://www.ncbi.nlm.nih.gov/pubmed/?term=%s"
    :keybinding "p")
  (defengine synonyms-thesaurus
    "https://www.thesaurus.com/browse/%s?s=t"
    :keybinding "s")
  ;; (engine/set-keymap-prefix (kbd "M-ñ s")

  ;;;~ set custom function to open URLs in private mode

  (setq engine/browser-function 'browse-url-firefox-private-mode)

  ;;;~ declare custom function to open URLs in private mode
  (defun browse-url-firefox-private-mode (url &optional new-window)
    "Ask the Firefox WWW browser to load URL in `--private-mode'.
A remastered version of the function `browse-url-firefox'."
    (interactive (browse-url-interactive-arg "URL: "))
    (setq url (browse-url-encode-url url))
    (let* ((process-environment (browse-url-process-environment)))
      (apply #'start-process
             (concat "firefox " url) nil
             browse-url-firefox-program
             (append
              browse-url-firefox-arguments
              ;; (if (browse-url-maybe-new-window new-window)
	      ;; 	(if browse-url-firefox-new-window-is-tab
	      ;; 	    '("-new-tab")
	      ;; 	  '("-new-window")))
	      '("-private-window")
              (list url)))))

  )

;;;~ emacs REPL customization  

(use-package comint                   
  :ensure nil
  :defer t
  :init
  (setq comint-scroll-to-bottom-on-input t)
  (setq comint-scroll-to-bottom-on-output t)
  (setq comint-move-point-for-output t))

;;;~ package to improve the searching menu: helm

(use-package helm
  :ensure t
  :defer t
  :bind (("C-x b" . helm-buffers-list)
	 ("C-x r b" . helm-bookmarks)
	 ;; ("M-x" . helm-M-x)
	 ("M-y" . helm-show-kill-ring)
	 ;; ("C-x C-f" . helm-find-files)
	 )
  :init

  ;;;~ WARNING: don't breack if hide-comnt.el not exists

  ;; (load "hide-comnt") ;; deprecated
  (let* ((mydir "~/.emacs.d/elisp")
	 (myfile "hide-comnt.el")
	 (entire-path (expand-file-name myfile mydir)))
    (if (file-exists-p entire-path)
	;;;~ open hide-comnt.el if exists
    	(load-file entire-path)
      ;;;~ download hide-comnt.el if not exists
      (progn
	(require 'url)
	;;;~ create required directory
	(if nil (file-directory-p mydir) (mkdir mydir t))
	;;;~ download file
	(url-copy-file 
	 "https://www.emacswiki.org/emacs/download/hide-comnt.el"
	 entire-path
	 t))))

  ;;;~ helm mode activation
  
  (helm-mode)

  :custom-face
  (helm-source-header
   ((t (:family "Ubuntu Mono"
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

;;;~ emacs snippets

(use-package yasnippet
  :ensure t
  :hook ((prog-mode . yas-minor-mode)
	 (org-mode . yas-minor-mode))

  ;;;~use pre-build snippets collection

  ;; :ensure yasnippet-snippets

  :init
  ;;;~ use custom snippets collection

  (setq yas-snippet-dirs
	`(,(expand-file-name "snippets"	user-emacs-directory)))

  (setq yas-indent-line 'none)

  :config 
  ;; (when (not (file-directory-p (expand-file-name "plugins/yasnippet" user-emacs-directory)))
  ;; (shell-command-as-string
  ;;  "cd ~/.emacs.d/plugins | git clone --recursive https://github.com/joaotavora/yasnippet"))
  (yas-reload-all)
  ;; (yas-global-mode)
  ;; :bind (:map yas-minor-mode-map
  ;; 		("TAB" . nil)
  ;; 		("<tab>" . nil))

  :bind  ("<C-f12>" . yas-minor-mode)
  )

  ;;;~ org global customization

  (use-package org
    :defer t
    :bind (("C-c a" . org-agenda)
	   ("C-c c" . org-capture)
	   ("C-c l" . org-store-link)
	   )
    :config
    ;; (setq org-directory
    ;;       (expand-file-name "../documents/org" user-emacs-directory))
    (setq org-adapt-indentation nil) 
    (setq org-confirm-babel-evaluate nil)
    (setq org-confirm-elisp-link-function nil)
    ;; (setq org-hide-emphasis-markers t) ;; hide markers: // ** == 
    (setq org-tags-column -66) 

    ;;;~ org babel customization

    (setq org-src-fontify-natively t) 
    (setq org-src-preserve-indentation t)  ;; do not indent code blocks
    (setq org-src-window-setup 'current-window) ;; eval in new frame

    ;;;~ open link in new window 

    (setq org-link-frame-setup
	  '((vm . vm-visit-folder-other-frame)
	    (vm-imap . vm-visit-imap-folder-other-frame)
	    (gnus . org-gnus-no-new-news)
	    (file . find-file)                 ;open link in new window  
	    ;; (file . find-file-other-window) ;open link in new window  
	    ;; (file . find-file-other-frame)  ;open link in new frame
	    (wl . wl-other-frame)))

    ;;;~ org custom templates

    (setq org-structure-template-alist
	  '(
	    ;;;~ text bloques
	    ("E" . "example")
	    ("M" . "comment")
	    ("N" . "notes")
	    ("Q" . "quote")
	    ;;;~ markup bloques
	    ("a" . "export ascii")
	    ("h" . "export html")
	    ("l" . "export latex")
	    ("x" . "export xml")
	    ;;;~ code bloques
	    ("0" . "src")
	    ("c" . "src C")
	    ("e" . "src emacs-lisp")
	    ("s" . "src shell :results verbatim")
	    ("b" . "src bash :results verbatim")
	    )
	  )	

    ;;;~ org add template
	
	  (add-to-list
	   'org-structure-template-alist
	   '("B" . "src bash :results verbatim :dir \"/sudo::/\"")
	   t				;added at the end
	   )

    ;;;~ org load babel languages

	  (org-babel-do-load-languages
	   'org-babel-load-languages
	   '(
	     (C          . t) ;; C, C++
	     ;; (R          . t)
	     ;; (clojure    . t)
	     ;; (ditaa      . t)
	     ;; (dot        . t) ;; graphviz-dot-mode
	     (emacs-lisp . t)
	     ;; (haskell    . t)
	     ;; (js         . t)
	     ;; (latex      . t)
	     (org        . t)
	     ;; (prolog     . t)
	     ;; (python     . t)
	     ;; (sh         . t)
	     (shell      . t)
	     ;; (sql        . t)
	     ;; (sqlite     . t)
	     ))

	  ;; perl support
	
	  (require 'ob-perl)
	
	  (use-package gnuplot
	    :ensure t
	    )

	  (use-package gnuplot-mode
	    :ensure t
	    )

	  ); end -- org --

;;;~ emacs start server mode (if not started previously)

(use-package server
  :ensure nil
  :config
  (unless (server-running-p)
    (server-start))
  )
