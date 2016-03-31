======================================================
 Tree style source code viewer for Javascript buffer
======================================================

You can view Javascript code (right) in a tree style viewer (left):

.. image:: https://github.com/linuxnotes/js-jedi-direx/blob/master/js-jedi-direx.png
   :target: https://github.com/linuxnotes/js-jedi-direx/blob/master/js-jedi-direx.png
 

Setup
=====
Example to open the viewer by `C-c x` in Python buffer::

	(require 'js2-jedi-direx)
	(defun js2-mode-complex-hook()
		((lambda ()
		 (define-key js-mode-map "\C-cx" 'js2-jedi-direx:pop-to-buffer)
		 (define-key js2-mode-map "\C-cx" 'js2-jedi-direx:pop-to-buffer)
		))
	)
	(define-key direx:direx-mode-map (kbd "O") 'js2-jedi-direx:find-item-other-window-and-close)
	(add-hook 'js2-mode-hook 'js2-mode-complex-hook)
  
Requirements
============

- `js2-mode.el <https://github.com/mooz/js2-mode.git>`_
- `direx.el <https://github.com/m2ym/direx-el>`_
- `jedi-direx <https://github.com/tkf/emacs-jedi-direx.git>`_
