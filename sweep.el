;;; sweep.el --- SWI-Prolog Embedded in Emacs -*- lexical-binding:t -*-

;; Copyright (C) 2022 Eshel Yaron

;; Authors: Eshel Yaron <me(at)eshelyaron(dot)com>
;; Maintainer: Eshel Yaron <me(at)eshelyaron(dot)com>
;; Keywords: prolog programming

;; This file is NOT part of GNU Emacs.

;;; Package-Version: 0.1.0
;;; Package-Requires: ((emacs "28"))

;;; Commentary:

;;; Code:

(defvar sweep-install-buffer-name "*Install sweep*"
  "Name of the buffer used for compiling sweep-module.")

(defun sweep-home-directory ()
  (file-name-directory (locate-library "sweep.el" t)))

;;;###autoload
(defun sweep-module-compile ()
  "Compile sweep-module."
  (interactive)
  (let* ((sweep-directory
          (shell-quote-argument (sweep-home-directory)))
         (make-commands
          (concat
           "cd " sweep-directory "; make; cd -"))
         (buffer (get-buffer-create sweep-install-buffer-name)))
    (pop-to-buffer buffer)
    (compilation-mode)
    (if (zerop (let ((inhibit-read-only t))
                 (call-process "sh" nil buffer t "-c" make-commands)))
        (message "Compilation of `sweep' module succeeded")
      (error "Compilation of `sweep' module failed!"))))

(unless (require 'sweep-module nil t)
  (if (y-or-n-p "Sweep needs `sweep-module' to work.  Compile it now? ")
      (progn
        (sweep-module-compile)
        (require 'sweep-module))
  (error "Sweep will not work until `sweep-module' is compiled!")))

(sweep-initialize (expand-file-name "bin/swipl"
                                    (sweep-home-directory))
                  "-q"
                  (expand-file-name "sweep.pl"
                                    (sweep-home-directory)))

(declare-function sweep-initialize "sweep-module")
(declare-function sweep-initialized-p "sweep-module")
(declare-function sweep-open-query "sweep-module")
(declare-function sweep-cut-query "sweep-module")
(declare-function sweep-close-query "sweep-module")
(declare-function sweep-cleanup "sweep-module")

(defun sweep-predicates-collection ()
  (sweep-open-query "user" "sweep" "sweep_predicates_collection" nil)
  (let ((sol (sweep-next-solution)))
    (sweep-close-query)
    (when (eq '! (car sol))
      (cdr sol))))

(defun sweep-predicate-location (mfn)
  (sweep-open-query "user" "sweep" "sweep_predicate_location" mfn)
  (let ((sol (sweep-next-solution)))
    (sweep-close-query)
    (let ((car (car sol)))
      (when (or (eq car '!)
                (eq car t))
        (cdr sol)))))

(defun sweep-read-predicate ()
  "Read a Prolog predicate (M:F/N) from the minibuffer, with completion."
  (let* ((col (sweep-predicates-collection)))
    (completing-read "Predicate: " col)))

(defun sweep-find-predicate (mfn)
  (interactive (list (sweep-read-predicate)))
  (let* ((loc (sweep-predicate-location mfn))
         (path (car loc))
         (line (cdr loc)))
    (find-file path)
    (goto-char (point-min))
    (forward-line (1- line))))

(defun sweep-modules-collection ()
  (sweep-open-query "user" "sweep" "sweep_modules_collection" nil)
  (let ((sol (sweep-next-solution)))
    (sweep-close-query)
    (when (eq '! (car sol))
      (cdr sol))))

(defun sweep-module-path (mod)
  (sweep-open-query "user" "sweep" "sweep_module_path" mod)
  (let ((sol (sweep-next-solution)))
    (sweep-close-query)
    (when (eq '! (car sol))
      (cdr sol))))

(defun sweep-read-module-name ()
  "Read a Prolog module name from the minibuffer, with completion."
  (let* ((col (sweep-modules-collection))
         (completion-extra-properties
          (list :annotation-function
                (lambda (key)
                  (concat (make-string (- 32 (length key)) ? )
                          (cdr (assoc-string key col)))))))
    (completing-read "Module: " col)))

(defun sweep-find-module (mod)
  (interactive (list (sweep-read-module-name)))
  (find-file (sweep-module-path mod)))

;;;; Testing:

;; (add-to-list 'load-path (file-name-directory (buffer-file-name)))
;; (require 'sweep)

(provide 'sweep)

;;; sweep.el ends here
