;;; jedi-direx.el --- Tree style source code viewer for Python buffer

;; Copyright (C) 2016 linuxnotes

;; Author: linuxnotes <linux.notes at mail.ru>
;; Package-Requires: ((jedi-direx "0.0.1alpha") (direx "0.1alpha"))
;; Version: 0.0.1alpha0

;; This file is NOT part of GNU Emacs.

;; js2-jedi-direx.el is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; js2-jedi-direx.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with jedi-direx.el.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;

;;; Code:

(add-to-list 'load-path "~/.emacs.d/emacs-python-environment")
(add-to-list 'load-path "~/.emacs.d/emacs-ctable")
(add-to-list 'load-path "~/.emacs.d/emacs-deferred")
(add-to-list 'load-path "~/.emacs.d/emacs-epc")
(add-to-list 'load-path "~/.emacs.d/emacs-jedi")
(add-to-list 'load-path "~/.emacs.d/direx-el")
(add-to-list 'load-path "~/.emacs.d/emacs-jedi-direx")

(require 'jedi-direx)
(require 'js2-mode)

(defun js2-jedi-direx:not-nil-listp (var)
  "check that var is list and not null"
  (if (and (listp var) (not (null var)))
	  t
	nil))

(defun js2-jedi-direx:make-cache-node (prop &optional type)
  "make node for create jedi-direx cache" 
  (if (null type)
	  (setq type "function")
	nil)
  (if (null prop) nil 
	(if (js2-jedi-direx:not-nil-listp prop)
		(progn
		  (list :name (car prop) :type type :column 1 :line_nr (line-number-at-pos (cadr prop)) :pos (cdr prop)))
	  (list :name prop :type type :column 1 :line_nr 1 :pos 1))))

(defun js2-jedi-direx:is-cache-node (prop) 
  "check if the prop is node"
  (if (and (not (null prop))
		   (or (not (js2-jedi-direx:not-nil-listp prop))
			   (and (= (length prop) 2)
					(not (js2-jedi-direx:not-nil-listp (car prop))) 
					(not (js2-jedi-direx:not-nil-listp (cadr prop))))
			   ))
	  t
	nil))

(defun js2-jedi-direx:node-type (prop)
  "get type of the node now can be class of function"
  (let ((result (if (not (js2-jedi-direx:not-nil-listp prop)) "class" "function")))
	result))


;; the main problem with this function was that for ("some" list need be deleted
;; but for ("some" linu_number) list should be added
(defun js2-jedi-direx:transform-tree (p-tree)
  "Main function that transform imenu tree from js2 to cache for jedi-direx"
  (if (null p-tree) 
	  nil 
	(if (js2-jedi-direx:is-cache-node (car p-tree))
		(progn 
		  (if (js2-jedi-direx:not-nil-listp (cdr p-tree)) 
			  (if (not (js2-jedi-direx:not-nil-listp (car p-tree)));; если простое свойство
				  (cons (js2-jedi-direx:make-cache-node (car p-tree) (js2-jedi-direx:node-type (car p-tree)))
						(car (js2-jedi-direx:transform-tree (cdr p-tree))))
				(cons (cons (js2-jedi-direx:make-cache-node (car p-tree) (js2-jedi-direx:node-type (car p-tree))) nil) 
					  (js2-jedi-direx:transform-tree (cdr p-tree)))
				)
			(if (not (js2-jedi-direx:not-nil-listp (car p-tree)))
				(cons (js2-jedi-direx:make-cache-node (car p-tree) (js2-jedi-direx:node-type (car p-tree))) nil)
			  (cons (cons (js2-jedi-direx:make-cache-node (car p-tree) (js2-jedi-direx:node-type (car p-tree))) nil) nil)))
		  )
	  (cons (js2-jedi-direx:transform-tree (car p-tree)) (js2-jedi-direx:transform-tree (cdr p-tree)))
	  )))

(defun js2-jedi-direx:get-names-cache() 
  "Create names cache that used for create tree"
  (interactive)
  (let* ((result (js2-browse-postprocess-chains))
		 (my-tree (js2-build-alist-trie result nil))
		 (result (js2-jedi-direx:transform-tree my-tree)))
    ;; test
	;; (setq result '(((:name "CTreeStore" :type "class" :column 1 :line_nr 1)
	;; 				((:name "CTreeStore2" :type "function" :column 1 :line_nr 3)))
	;; 			   ((:name "CTreeStore1" :type "function" :column 2 :line_nr 2))
	;; 			   )
	;; 	  )
    result))

(defun js2-jedi-direx:-goto-item(&optional item)
  (interactive)
  (let ((item1 item))
	(if (null item1)
		(setq item1 (direx:item-tree (direx:item-at-point!)))
	  (setq item1 (direx:item-tree item))
	  )
	(let* (
		   (cur-item-prop (car (oref item1 :cache)))
		   (root (direx:item-root item))
		   (filename nil))
	  (setq filename (direx:file-full-name (direx:item-tree root)))
	  (find-file-other-window filename)
	  (destructuring-bind (&key pos column &allow-other-keys) cur-item-prop
		(goto-char pos)
		)
	  ))
  )

(defun js2-jedi-direx:find-item-other-window-and-close (&optional item)
  (interactive)
  (setq item (or item (direx:item-at-point!)))
  (js2-jedi-direx:generic-find-item-and-close item t))

(defmethod js2-jedi-direx:generic-find-item-and-close ((item jedi-direx:item)
											 not-this-window)
  "Overriting of method find item, such that tree will be close after select"
  (let* ((root (direx:item-root item))
         (filename (direx:file-full-name (direx:item-tree root)))
         (curwin (get-buffer-window (current-buffer))))
    (if not-this-window
        (progn 
          (find-file-other-window filename)
          (quit-window nil curwin))
      (find-file filename))
    (direx-jedi:-goto-item item)))

(defun js2-jedi-direx:make-buffer ()
  (direx:ensure-buffer-for-root
   (make-instance 'jedi-direx:module
                  :name (format "*direx-jedi: %s*" (buffer-name))
                  :buffer (current-buffer)
                  :file-name (buffer-file-name)
                  :cache (cons nil (js2-jedi-direx:get-names-cache))))
)

(defun js2-jedi-direx:pop-to-buffer ()
  (interactive)
  (js2-imenu-extras-mode t)
  (pop-to-buffer (js2-jedi-direx:make-buffer)))

(defun js2-jedi-direx:switch-to-buffer ()
  (interactive)
  (switch-to-buffer (js2-jedi-direx:make-buffer)))

(define-key direx:direx-mode-map (kbd "O")           'js2-jedi-direx:find-item-other-window-and-close)

;;; for tests
;; (defun show-browse-postprocess-chains() 
;;   (interactive)
;;   (let* ((result (js2-browse-postprocess-chains))
;; 		 (my-tree (js2-build-alist-trie result nil))
;; 		 )
;; 	;;(let ((result (js2-parse (current-buffer))))
;; 	;;(message "%s" result)
;;     (message "%s"(js2-jedi-direx:transform-tree my-tree))
;;     ;;(message "%s" (pp-to-string js2-imenu-recorder))
;;     ;;(message "%s" (car js2-imenu-function-map))
;; 	nil))

(provide 'js2-jedi-direx)
(provide 'js2-direx-jedi)
