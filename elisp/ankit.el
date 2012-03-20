;;
;; Anki helper elisp
;;

(defvar ankit-script-name
  "bash -l -c 'source $HOME/.rvm/scripts/rvm && rvm use 1.9.3 > /dev/null && cd ~/work/ankit && ruby -Ilib bin/ankit %s'")

;;
;; Defualt global key:
;; * C-x a n : Open new card buffer. The card will be added to the default directory.
;; * C-x a N : Open new card buffer. The card will be added to the directory you are in.
;; 

(defun ankit-define-key-default ()
  (interactive)
  (define-prefix-command 'ctl-x-a-map)
  (define-key ctl-x-map "a" 'ctl-x-a-map)
  (define-key ctl-x-a-map "n" 'ankit-ask-add)
  (define-key ctl-x-a-map "N" 'ankit-ask-add-default)
  (define-key ctl-x-a-map "h" 'ankit-ask-add-here))

;;
;; Defining a mode:
;; 
;; * C-c C-c : Add current buffer as a new card and close the buffer.
;; * C-c C-m : Add current buffer as a new card and open another.
;;

(define-derived-mode ankit-mode nil "Anki" "A mode for editing anki card buffers")
(define-key ankit-mode-map "\C-c\C-i" 'ankit-insert-template)
(define-key ankit-mode-map "\C-c\C-c" 'ankit-add-buffer-and-kill)
(define-key ankit-mode-map "\C-c\C-m" 'ankit-add-buffer-and-more)

;;
;; Commands
;;
(defun ankit-insert-template ()
  (interactive)
  (goto-char (point-min))
  (insert "O: \nT: \n\n")
  (goto-char (point-min))
  (move-end-of-line nil))

(defun ankit-clear-deck-name ()
  (interactive)
  (setq ankit-deck-name nil))

(defun ankit-ask-add-default ()
  (interactive)
  (ankit-ask-add nil))

(defun ankit-ask-add-here ()
  (interactive)
  (ankit-ask-add (dired-current-directory)))

(defun ankit-ask-add-again ()
  (ankit-ask-add ankit-card-dir))

(defun ankit-ask-add (dir)
  (interactive "DCard path:")
  (setq ankit-card-dir dir)
  (let ((source-buffer (generate-new-buffer "*ankit-asking-add*")))
    (switch-to-buffer source-buffer)
    (ankit-mode)
    (ankit-insert-template)
    ))

(defun ankit-add-buffer-and-kill ()
  (interactive)
  (let*
      ((the-buffer (current-buffer)))
    (ankit-add-buffer the-buffer 'ankit-add-buffer-handle-done)
    (kill-buffer the-buffer)))

(defun ankit-add-buffer-and-more ()
  (interactive)
  (let*
      ((the-buffer (current-buffer)))
    (ankit-add-buffer the-buffer 'ankit-add-buffer-handle-done)
    (kill-buffer the-buffer)
    (ankit-ask-add-again)))

;;
;; internals
;;
(defun ankit-add-buffer (buffer finish-fn)
  (let* ((script-path (format ankit-script-name (ankit-add-build-command-extra)))
	 (out-buffer (generate-new-buffer "*ankit-add-out*"))
	 (program (start-process-shell-command "ankit" out-buffer script-path)))
    (set-process-sentinel program finish-fn)
    (process-send-string program (with-current-buffer buffer (buffer-string)))
    (process-send-eof program)))

;; http://www.emacswiki.org/emacs/ElispCookbook
(defun ankit-chomp (str)
      "Chomp leading and tailing whitespace from STR."
      (while (string-match "\\`\n+\\|^\\s-+\\|\\s-+$\\|\n+\\'"
                           str)
        (setq str (replace-match "" t t str)))
      str)

(defun ankit-add-build-command-extra ()
  (let*
      ((base " add --stdin")
       (dirspec (if (stringp ankit-card-dir) (format "--dir %s" ankit-card-dir) "")))
    (format "%s %s" base dirspec)))

(defun ankit-add-buffer-handle-done (proc event)
  (let*
      ((out-buffer (process-buffer proc))
       (out-text (with-current-buffer out-buffer (buffer-string))))
    (kill-buffer out-buffer)
    (message "Ankit: %s" (ankit-chomp out-text))))

(provide 'ankit)