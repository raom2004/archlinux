;;;~ init-openbox.el
;;;~
;;;~ Description:
;;;~  emacs init file that include other relevant dot-files,
;;;~  open and fullfil the screen with three buffers,
;;;~  and finally set which files will be shown in each buffer

;;;~ FRAME 1: load custom init file: user-init-file
(progn
  (org-mode)
  ;;;~ set custom init file 
  (setq user-init-file "~/.emacs.d/init-openbox.el")
  ;;;~ open the custom init file
  (find-file user-init-file)
  ;;;~ load other init files:
  ;;;~  * basic configuration
  (load-file "~/Projects/dot-emacs/init-essentials.el")
  ;; (find-file "~/Projects/dot-emacs/init-essentials.el")
  ;;;~  * show startup message
  (load-file "~/Projects/dot-emacs/init-startup-time.el")
  ;; (find-file "~/Projects/dot-emacs/init-startup-time.el")
  ;;;~  * dont show startup statistics
  (remove-hook 'emacs-startup-hook 'use-package-report)
  ;;;~ customize scratch buffer (didn't work)
  ;; (setq initial-major-mode 'sh-mode); originally emacs-lisp-mode
  ;;;~ buffer to show after starting emacs
  ;; (setq initial-buffer-choice user-init-file)
  )

;;;~ FRAME 2: open openbox configuration files in new frame
(progn
  (make-frame)
  (other-frame 1)
  ;;;~ config files
  ;; (find-file "~/.config/openbox/rc.xml")
  (find-file "~/Projects/archlinux/desktop/openbox/shortcuts-openbox.sh")
  (find-file "~/Projects/archlinux/desktop/openbox/conky.org")
  (find-file "~/Projects/archlinux/desktop/openbox/autostart")

;;;~ FRAME 3:
  (progn
    ;; (add-hook 'emacs-startup-hook
    ;; 	    #'(lambda ()
    ;; 		(interactive)
    (make-frame)
    (other-frame 1)
    (other-frame 1)
    (modify-frame-location-upper-right)
    (switch-to-buffer "*scratch*")
    (find-file
     "~/Projects/dot-emacs/src-org/init-essentials.org")
    (other-frame 1)
    ))
