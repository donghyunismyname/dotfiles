; Disable Welcome Message
(setq inhibit-startup-message t)


; Theme (may be overriden)
(load-theme 'wombat)


; Turn off
(menu-bar-mode -1)
(tool-bar-mode -1)


; Visual signal instead of alarm sound
(setq visible-bell t)


;; Make ESC quit prompts
(global-set-key (kbd "<escape>") 'keyboard-escape-quit)


;; Initialize package sources
(require 'package)
(setq package-archives '(
    ("melpa" . "https://melpa.org/packages/")
    ("org" . "https://orgmode.org/elpa/")
    ("elpa" . "https://elpa.gnu.org/packages/")))
(package-initialize)
(unless package-archive-contents
   (package-refresh-contents))


;; Initialize use-package on non-Linux platforms
(unless (package-installed-p 'use-package)
     (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)


; ??? not sure what it is
(use-package command-log-mode)


; The line at the bottom of screen
(use-package doom-modeline
    :ensure t
    :init (doom-modeline-mode 1)
    :custom ((doom-modeline-height 15)))


; Theme
(use-package zenburn-theme
    :ensure t
    :config
    (load-theme 'zenburn t))



