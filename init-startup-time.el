;;;~ ./init-startup-time.el
;;;~ show use-init-file after emacs startup 
(add-hook
 'emacs-startup-hook
 (lambda()
   (message
    "Welcome %s
Emacs version: %s\t%s\tload time: %s
user-init-file: %s"
    (propertize
     (format "%s" (capitalize user-login-name))
     'face
     'font-lock-builtin-face)
    (propertize
     emacs-version
     'face
     'font-lock-keyword-face)
    (format "Org version: %s"
	    (if (boundp 'org-version)
		(propertize
		 org-version
		 'face
		 'font-lock-keyword-face)
	    "not loaded yet"))
    (propertize
     (emacs-init-time "%.2f sec")
     'face
     'font-lock-keyword-face)
    (propertize
     user-init-file
     'face
     'font-lock-keyword-face))))
