; Disable Welcome Message
(setq inhibit-startup-message t)


; Theme (may be overriden)
(load-theme 'wombat)


; Turn off useless UI
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
    :custom ((doom-modeline-height 15)
             (doom-modeline-unicode-fallback nil)))
; (setq doom-modeline-buffer-state-icon nil)
; (setq doom-modeline-buffer-modification-icon nil)
(setq doom-modeline-icon nil) ; letters instead of icons to display properly


; Theme
; (use-package zenburn-theme
;     :ensure t
;     :config
;     (load-theme 'zenburn t))


; line/column numbers
(column-number-mode)
(global-display-line-numbers-mode t)


; shfit+arrow to move between windows
(windmove-default-keybindings)


; Cursor options
(global-hl-line-mode)
(blink-cursor-mode 0)
(setq-default cursor-type 'bar)



(use-package general
:config
(general-evil-setup t)

(general-create-definer rune/leader-keys
:keymaps '(normal insert visual emacs)
:prefix "SPC"
:global-prefix "C-SPC"))

(rune/leader-keys
"t"  '(:ignore t :which-key "toggles")
"tt" '(counsel-load-theme :which-key "choose theme"))

(defun rune/evil-hook ()
(dolist (mode '(custom-mode
eshell-mode
git-rebase-mode
erc-mode
circe-server-mode
circe-chat-mode
circe-query-mode
sauron-mode
term-mode))
(add-to-list 'evil-emacs-state-modes mode)))

(use-package evil
:init
(setq evil-want-integration t)
(setq evil-want-keybinding nil)
(setq evil-want-C-u-scroll t)
(setq evil-want-C-i-jump nil)
:hook (evil-mode . rune/evil-hook)
:config
(evil-mode 1)
(define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
(define-key evil-insert-state-map (kbd "C-h") 'evil-delete-backward-char-and-join)

;; Use visual line motions even outside of visual-line-mode buffers
(evil-global-set-key 'motion "j" 'evil-next-visual-line)
(evil-global-set-key 'motion "k" 'evil-previous-visual-line)

(evil-set-initial-state 'messages-buffer-mode 'normal)
(evil-set-initial-state 'dashboard-mode 'normal))

(use-package evil-collection
:after evil
:config
(evil-collection-init))

;; Mention evil-collection-mode-list

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(evil-collection evil general zenburn-theme use-package timu-spacegrey-theme timu-macos-theme doom-modeline command-log-mode)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
