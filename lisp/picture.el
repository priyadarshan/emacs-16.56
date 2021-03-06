;; "Picture mode" -- editing using quarter-plane screen model.
;; Copyright (C) 1985 Richard M. Stallman and K. Shane Hartman
;; This file is part of GNU Emacs.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but without any warranty.  No author or distributor
;; accepts responsibility to anyone for the consequences of using it
;; or for whether it serves any particular purpose or works at all,
;; unless he says so in writing.

;; Everyone is granted permission to copy, modify and redistribute
;; GNU Emacs, but only under the conditions described in the
;; document "GNU Emacs copying permission notice".   An exact copy
;; of the document is supposed to have been given to you along with
;; GNU Emacs so that you can know how you may redistribute it all.
;; It should be in a file named COPYING.  Among other things, the
;; copyright notice and this notice must be preserved on all copies.

(defun move-to-column-force (column)
  "Move to column COLUMN in current line.
Differs from move-to-column in that it creates or modifies whitespace
if necessary to attain exactly the specified column."
  (move-to-column column)
  (let ((col (current-column)))
    (if (< col column)
	(indent-to column)
      (if (and (/= col column)
	       (= (preceding-char) ?\t))
	  (let (indent-tabs-mode)
	    (delete-char -1)
            (indent-to col)
            (move-to-column column))))))


;; Picture Movement Commands

(defun Picture-end-of-line (&optional arg)
  "Position dot after last non-blank character on current line.
With ARG not nil, move forward ARG - 1 lines first.
If scan reaches end of buffer, stop there without error."
  (interactive "P")
  (if arg (forward-line (1- (prefix-numeric-value arg))))
  (beginning-of-line)
  (skip-chars-backward " \t" (prog1 (dot) (end-of-line))))

(defun Picture-forward-column (arg)
  "Move cursor right, making whitespace if necessary.
With argument, move that many columns."
  (interactive "p")
  (move-to-column-force (+ (current-column) arg)))

(defun Picture-backward-column (arg)
  "Move cursor left, making whitespace if necessary.
With argument, move that many columns."
  (interactive "p")
  (move-to-column-force (- (current-column) arg)))

(defun Picture-move-down (arg)
  "Move vertically down, making whitespace if necessary.
With argument, move that many lines."
  (interactive "p")
  (let ((col (current-column)))
    (Picture-newline arg)
    (move-to-column-force col)))

(defconst picture-vertical-step 0
  "Amount to move vertically after text character in Picture mode.")

(defconst picture-horizontal-step 1
  "Amount to move horizontally after text character in Picture mode.")

(defun Picture-move-up (arg)
  "Move vertically up, making whitespace if necessary.
With argument, move that many lines."
  (interactive "p")
  (Picture-move-down (- arg)))

(defun picture-movement-right ()
  "Move right after self-inserting character in Picture mode."
  (interactive)
  (Picture-set-motion 0 1))

(defun picture-movement-left ()
  "Move left after self-inserting character in Picture mode."
  (interactive)
  (Picture-set-motion 0 -1))

(defun picture-movement-up ()
  "Move up after self-inserting character in Picture mode."
  (interactive)
  (Picture-set-motion -1 0))

(defun picture-movement-down ()
  "Move down after self-inserting character in Picture mode."
  (interactive)
  (Picture-set-motion 1 0))

(defun picture-movement-nw ()
  "Move up and left after self-inserting character in Picture mode."
  (interactive)
  (Picture-set-motion -1 -1))

(defun picture-movement-ne ()
  "Move up and right after self-inserting character in Picture mode."
  (interactive)
  (Picture-set-motion -1 1))

(defun picture-movement-sw ()
  "Move down and left after self-inserting character in Picture mode."
  (interactive)
  (Picture-set-motion 1 -1))

(defun picture-movement-se ()
  "Move down and right after self-inserting character in Picture mode."
  (interactive)
  (Picture-set-motion 1 1))

(defun Picture-set-motion (vert horiz)
  "Set VERTICAL and HORIZONTAL increments for movement in Picture mode.
The mode line is updated to reflect the current direction."
  (setq picture-vertical-step vert
	picture-horizontal-step horiz)
  (setq mode-name
	(format "Picture:%s"
		(car (nthcdr (+ 1 (% horiz 2) (* 3 (1+ (% vert 2))))
			     '(nw up ne left none right sw down se)))))
  ;; Kludge - force the mode line to be updated.  Is there a better
  ;; way to this?
  (set-buffer-modified-p (buffer-modified-p))
  (message ""))

(defun Picture-move ()
  "Move in direction of  picture-vertical-step  and  picture-horizontal-step."
  (Picture-move-down picture-vertical-step)
  (Picture-forward-column picture-horizontal-step))

(defun Picture-motion (arg)
  "Move dot in direction of current picture motion in Picture mode.
With ARG do it that many times.  Useful for delineating rectangles in
conjunction with diagonal picture motion.
Do \\[command-apropos]  picture-movement  to see commands which control motion."
  (interactive "p")
  (Picture-move-down (* arg picture-vertical-step))
  (Picture-forward-column (* arg picture-horizontal-step)))

(defun Picture-motion-reverse (arg)
  "Move dot in direction opposite of current picture motion in Picture mode.
With ARG do it that many times.  Useful for delineating rectangles in
conjunction with diagonal picture motion.
Do \\[command-apropos]  picture-movement  to see commands which control motion."
  (interactive "p")
  (Picture-motion (- arg)))


;; Picture insertion and deletion.

(defun Picture-self-insert (arg)
  "Insert this character in place of character previously at the cursor.
The cursor then moves in the direction you previously specified
with the commands picture-movement-right, picture-movement-up, etc.
Do \\[command-apropos]  picture-movement  to see those commands."
  (interactive "p")
  (while (> arg 0)
    (setq arg (1- arg))
    (move-to-column-force (1+ (current-column)))
    (delete-char -1)
    (insert last-input-char)
    (forward-char -1)
    (Picture-move)))

(defun Picture-clear-column (arg)
  "Clear out ARG columns after dot without moving."
  (interactive "p")
  (let* ((odot (dot))
	 (original-col (current-column))
	 (target-col (+ original-col arg)))
    (move-to-column-force target-col)
    (delete-region odot (dot))
    (save-excursion
     (indent-to (max target-col original-col)))))

(defun Picture-backward-clear-column (arg)
  "Clear out ARG columns before dot, moving back over them."
  (interactive "p")
  (Picture-clear-column (- arg)))

(defun Picture-clear-line (arg)
  "Clear out rest of line; if at end of line, advance to next line.
Cleared-out line text goes into the kill ring, as do
newlines that are advanced over.
With argument, clear out (and save in kill ring) that many lines."
  (interactive "P")
  (if arg
      (progn
       (setq arg (prefix-numeric-value arg))
       (kill-region (dot) (scan-buffer (dot) (if (> arg 0) arg (- arg 1)) ?\n))
       (newline (if (> arg 0) arg (- arg))))
    (if (looking-at "[ \t]*$")
	(kill-ring-save (dot) (progn (forward-line 1) (dot)))
      (kill-region (dot) (progn (end-of-line) (dot))))))

(defun Picture-newline (arg)
  "Move to the beginning of the following line.
With argument, moves that many lines (up, if negative argument);
always moves to the beginning of a line."
  (interactive "p")
  (if (< arg 0)
      (forward-line arg)
    (while (> arg 0)
      (end-of-line)
      (if (eobp) (newline) (forward-char 1))
      (setq arg (1- arg)))))

(defun Picture-open-line (arg)
  "Insert an empty line after the current line.
With positive argument insert that many lines."
  (interactive "p")
  (save-excursion
   (end-of-line)
   (open-line arg)))

(defun Picture-duplicate-line ()
  "Insert a duplicate of the current line, below it."
  (interactive)
  (save-excursion
   (let ((contents
	  (buffer-substring
	   (progn (beginning-of-line) (dot))
	   (progn (Picture-newline 1) (dot)))))
     (forward-line -1)
     (insert contents))))


;; Picture Tabs

(defvar picture-tab-chars "!-~"
  "*A character set which controls behavior of commands
\\[Picture-set-tab-stops] and \\[Picture-tab-search].  It is NOT a
regular expression, any regexp special characters will be quoted.
It defines a set of \"interesting characters\" to look for when setting
\(or searching for) tab stops, initially \"!-~\" (all printing characters).
For example, suppose that you are editing a table which is formatted thus:
| foo		| bar + baz | 23  *
| bubbles	| and + etc | 97  *
and that picture-tab-chars is \"|+*\".  Then invoking
\\[Picture-set-tab-stops] on either of the previous lines would result
in the following tab stops
		:     :     :     :
Another example - \"A-Za-z0-9\" would produce the tab stops
  :		  :	:     :

Note that if you want the character `-' to be in the set, it must be
included in a range or else appear in a context where it cannot be
taken for indicating a range (e.g. \"-A-Z\" declares the set to be the
letters `A' through `Z' and the character `-').  If you want the
character `\\' in the set it must be preceded by itself: \"\\\\\".

The command \\[Picture-tab-search] is defined to move beneath (or to) a
character belonging to this set independent of the tab stops list.")

(defun Picture-set-tab-stops (&optional arg)
  "Set value of  tab-stop-list  according to context of this line.
This controls the behavior of \\[Picture-tab].  A tab stop
is set at every column occupied by an \"interesting character\" that is
preceded by whitespace.  Interesting characters are defined by the
variable  picture-tab-chars,  see its documentation for an example
of usage.  With ARG, just (re)set  tab-stop-list  to its default value.
The tab stops computed are displayed in the minibuffer with `:' at
each stop."
  (interactive "P")
  (save-excursion
    (let (tabs)
      (if arg
	  (setq tabs (default-value 'tab-stop-list))
	(let ((regexp (concat "[ \t]+[" (regexp-quote picture-tab-chars) "]")))
	  (beginning-of-line)
	  (let ((bol (dot)))
	    (end-of-line)
	    (while (re-search-backward regexp bol t)
	      (skip-chars-forward " \t")
	      (setq tabs (cons (current-column) tabs)))
	    (if (null tabs)
		(error "No characters in set %s on this line."
		       (regexp-quote picture-tab-chars))))))
      (setq tab-stop-list tabs)
      (let ((blurb (make-string (1+ (nth (1- (length tabs)) tabs)) ?\ )))
	(while tabs
	  (aset blurb (car tabs) ?:)
	  (setq tabs (cdr tabs)))
	(message blurb)))))

(defun Picture-tab-search (&optional arg)
  "Move to column beneath next interesting char in previous line.
With ARG move to column occupied by next interesting character in this
line.  The character must be preceded by whitespace.
\"interesting characters\" are defined by variable  picture-tab-chars.
If no such character is found, move to beginning of line."
  (interactive "P")
  (let ((target (current-column)))
    (save-excursion
      (if (and (not arg)
	       (progn
		 (beginning-of-line)
		 (skip-chars-backward
		  (concat "^" (regexp-quote picture-tab-chars))
		  (dot-min))
		 (not (bobp))))
	  (move-to-column target))
      (if (re-search-forward
	   (concat "[ \t]+[" (regexp-quote picture-tab-chars) "]")
	   (save-excursion (end-of-line) (dot))
	   'move)
	  (setq target (1- (current-column)))
	(setq target nil)))
    (if target
	(move-to-column-force target)
      (beginning-of-line))))

(defun Picture-tab (&optional arg)
  "Tab transparently (move) to next tab stop.
With ARG overwrite the traversed text with spaces.  The tab stop
list can be changed by \\[Picture-set-tab-stops] and \\[edit-tab-stops].
See also documentation for variable  picture-tab-chars."
  (interactive "P")
  (let* ((odot (dot))
	 (target (prog2 (tab-to-tab-stop)
			(current-column)
			(delete-region odot (dot)))))
    (move-to-column-force target)
    (if arg
	(let (indent-tabs-mode)
	  (delete-region odot dot)
	  (indent-to target)))))


;; Picture Rectangles

(defconst picture-killed-rectangle nil
  "Rectangle killed or copied by \\[Picture-clear-rectangle] in Picture mode.
The contents can be retrieved by \\[Picture-yank-rectangle]")

(defun Picture-clear-rectangle (start end register &optional killp)
  "Clear and save rectangle delineated by dot and mark.
The rectangle is saved for yanking by \\[Picture-yank-rectangle] and replaced
with whitespace.  The previously saved rectangle, if any, is lost.
With prefix argument, the rectangle is actually killed, shifting remaining
text."
  (interactive "r\nP")
  (setq picture-killed-rectangle (Picture-snarf-rectangle start end killp)))

(defun Picture-clear-rectangle-to-register (start end register &optional killp)
  "Clear rectangle delineated by dot and mark into REGISTER.
The rectangle is saved in REGISTER and replaced with whitespace.
With prefix argument, the rectangle is actually killed, shifting remaining
text."
  (interactive "r\ncRectangle to register: \nP")
  (set-register register (Picture-snarf-rectangle start end killp)))

(defun Picture-snarf-rectangle (start end &optional killp)
  (let ((column (current-column))
	(indent-tabs-mode nil))
    (prog1 (save-excursion
             (if killp
                 (delete-extract-rectangle start end)
               (prog1 (extract-rectangle start end)
                      (clear-rectangle start end))))
	   (move-to-column-force column))))

(defun Picture-yank-rectangle (&optional insertp)
  "Overlay rectangle saved by \\[Picture-clear-rectangle]
The rectangle is positioned with upper left corner at dot, overwriting
existing text.  With prefix argument, the rectangle is inserted instead,
shifting existing text.  Leaves mark at one corner of rectangle and
dot at the other (diagonally opposed) corner."
  (interactive "P")
  (if (not (consp picture-killed-rectangle))
      (error "No rectangle saved.")
    (Picture-insert-rectangle picture-killed-rectangle insertp)))

(defun Picture-yank-rectangle-from-register (register &optional insertp)
  "Overlay rectangle saved in REGISTER.
The rectangle is positioned with upper left corner at dot, overwriting
existing text.  With prefix argument, the rectangle is
inserted instead, shifting existing text.  Leaves mark at one corner
of rectangle and dot at the other (diagonally opposed) corner."
  (interactive "cRectangle from register: \nP")
  (let ((rectangle (get-register register)))
    (if (not (consp rectangle))
	(error "Register %c does not contain a rectangle." register)
      (Picture-insert-rectangle rectangle insertp))))

(defun Picture-insert-rectangle (rectangle &optional insertp)
  "Overlay RECTANGLE with upper left corner at dot.
Optional argument INSERTP, if non-nil causes RECTANGLE to be inserted.
Leaves the region surrounding the rectangle."
  (let ((indent-tabs-mode nil))
    (if (not insertp)
	(save-excursion
	  (delete-rectangle (dot)
			    (progn
			      (Picture-forward-column (length (car rectangle)))
			      (Picture-move-down (1- (length rectangle)))
			      (dot)))))
    (push-mark)
    (insert-rectangle rectangle)))


;; Picture Keymap, entry and exit points.

(defconst picture-mode-map nil)

(if (not picture-mode-map)
    (let ((i ?\ ))
      (setq picture-mode-map (make-keymap))
      (while (< i ?\177)
        (aset picture-mode-map i 'Picture-self-insert)
	(setq i (1+ i)))
      (define-key picture-mode-map "\C-f" 'Picture-forward-column)
      (define-key picture-mode-map "\C-b" 'Picture-backward-column)
      (define-key picture-mode-map "\C-d" 'Picture-clear-column)
      (define-key picture-mode-map "\C-c\C-d" 'delete-char)
      (define-key picture-mode-map "\177" 'Picture-backward-clear-column)
      (define-key picture-mode-map "\C-k" 'Picture-clear-line)
      (define-key picture-mode-map "\C-o" 'Picture-open-line)
      (define-key picture-mode-map "\C-m" 'Picture-newline)
      (define-key picture-mode-map "\C-j" 'Picture-duplicate-line)
      (define-key picture-mode-map "\C-n" 'Picture-move-down)
      (define-key picture-mode-map "\C-p" 'Picture-move-up)
      (define-key picture-mode-map "\C-e" 'Picture-end-of-line)
      (define-key picture-mode-map "\e\t" 'Picture-toggle-tab-state)
      (define-key picture-mode-map "\t" 'Picture-tab)
      (define-key picture-mode-map "\e\t" 'Picture-tab-search)
      (define-key picture-mode-map "\C-c\t" 'Picture-set-tab-stops)
      (define-key picture-mode-map "\C-c\C-k" 'Picture-clear-rectangle)
      (define-key picture-mode-map "\C-ck" 'Picture-clear-rectangle-to-register)
      (define-key picture-mode-map "\C-c\C-y" 'Picture-yank-rectangle)
      (define-key picture-mode-map "\C-cy" 'Picture-yank-rectangle-from-register)
      (define-key picture-mode-map "\C-c\C-c" 'Picture-mode-exit)
      (define-key picture-mode-map "\C-c\C-f" 'Picture-motion)
      (define-key picture-mode-map "\C-c\C-b" 'Picture-motion-reverse)
      (define-key picture-mode-map "\e`" 'picture-movement-left)
      (define-key picture-mode-map "\e'" 'picture-movement-right)
      (define-key picture-mode-map "\e-" 'picture-movement-up)
      (define-key picture-mode-map "\e=" 'picture-movement-down)
      (define-key picture-mode-map "\C-c`" 'picture-movement-nw)
      (define-key picture-mode-map "\C-c'" 'picture-movement-ne)
      (define-key picture-mode-map "\C-c/" 'picture-movement-sw)
      (define-key picture-mode-map "\C-c\\" 'picture-movement-se)))

(defvar edit-picture-hook nil
  "If non-nil, it's value is called on entry to Picture mode.
Picture mode is invoked by the command \\[edit-picture].")

(defun edit-picture ()
  "Switch to Picture mode, in which a quarter-plane screen model is used.
Printing characters replace instead of inserting themselves with motion
afterwards settable by these commands:
  M-`	  Move left after insertion.
  M-'	  Move right after insertion.
  M--	  Move up after insertion.
  M-=	  Move down after insertion.
  C-c `	  Move northwest (nw) after insertion.
  C-c '	  Move northeast (ne) after insertion.
  C-c /	  Move southwest (sw) after insertion.
  C-c \\   Move southeast (se) after insertion.
The current direction is displayed in the mode line.  The initial
direction is right.  Whitespace is inserted and tabs are changed to
spaces when required by movement.  You can move around in the buffer
with these commands:
  C-p	  Move vertically to SAME column in previous line.
  C-n	  Move vertically to SAME column in next line.
  C-e	  Move to column following last non-whitespace character.
  C-f	  Move right inserting spaces if required.
  C-b	  Move left changing tabs to spaces if required.
  C-c C-f Move in direction of current picture motion.
  C-c C-b Move in opposite direction of current picture motion.
  Return  Move to beginning of next line.
You can edit tabular text with these commands:
  M-Tab	  Move to column beneath (or at) next interesting charecter.
	    `Indents' relative to a previous line.
  Tab	  Move to next stop in tab stop list.
  C-c Tab Set tab stops according to context of this line.
	    With ARG resets tab stops to default (global) value.
	    See also documentation of variable	picture-tab-chars
	    which defines \"interesting character\".  You can manually
	    change the tab stop list with command \\[edit-tab-stops].
You can manipulate text with these commands:
  C-d	  Clear (replace) ARG columns after dot without moving.
  C-c C-d Delete char at dot - the command normally assigned to C-d.
  Delete  Clear (replace) ARG columns before dot, moving back over them.
  C-k	  Clear ARG lines, advancing over them.	 The cleared
	    text is saved in the kill ring.
  C-o	  Open blank line(s) beneath current line.
You can manipulate rectangles with these commands:
  C-c C-k Clear (or kill) a rectangle and save it.
  C-c k	  Like C-c C-k except rectangle is saved in named register.
  C-c C-y Overlay (or insert) currently saved rectangle at dot.
  C-c y	  Like C-c C-y except rectangle is taken from named register.
  \\[copy-rectangle-to-register]   Copies a rectangle to a register.
  \\[advertised-undo]   Can undo effects of rectangle overlay commands
	    commands if invoked soon enough.
You can return to the previous mode with:
  C-c C-c Which also strips trailing whitespace from every line.
	    Stripping is suppressed by supplying an argument.

Entry to this mode calls the value of  edit-picture-hook  if non-nil.

Note that Picture mode commands will work outside of Picture mode, but
they are not defaultly assigned to keys."
  (interactive)
  (if (eq major-mode 'edit-picture)
      (error "You are already editing a Picture.")
    (make-local-variable 'Picture-mode-old-local-map)
    (setq Picture-mode-old-local-map (current-local-map))
    (use-local-map picture-mode-map)
    (make-local-variable 'Picture-mode-old-mode-name)
    (setq Picture-mode-old-mode-name mode-name)
    (make-local-variable 'Picture-mode-old-major-mode)
    (setq Picture-mode-old-major-mode major-mode)
    (setq major-mode 'edit-picture)
    (make-local-variable 'picture-killed-rectangle)
    (setq picture-killed-rectangle nil)
    (make-local-variable 'tab-stop-list)
    (setq tab-stop-list (default-value 'tab-stop-list))
    (make-local-variable 'picture-tab-chars)
    (setq picture-tab-chars (default-value 'picture-tab-chars))
    (make-local-variable 'Picture-vertical-step)
    (make-local-variable 'Picture-horizontal-step)
    (Picture-set-motion 0 1)
    (and (boundp 'edit-picture-hook)
	 edit-picture-hook
	 (funcall edit-picture-hook))
    (message
     (substitute-command-keys
      "Type \\[Picture-mode-exit] in this buffer to return it to %s mode.")
     Picture-mode-old-mode-name)))

(fset 'picture-mode 'edit-picture)	; for the confused

(defun Picture-mode-exit (&optional nostrip)
  "Undo edit-picture and return to previous major mode.
With no argument strips whitespace from end of every line in Picture buffer
  otherwise just return to previous mode."
  (interactive "P")
  (if (not (eq major-mode 'edit-picture))
      (error "You aren't editing a Picture.")
    (if (not nostrip) (Picture-clean))
    (setq mode-name Picture-mode-old-mode-name)
    (use-local-map Picture-mode-old-local-map)
    (setq major-mode Picture-mode-old-major-mode)
    (kill-local-variable 'tab-stop-list)
    ;; Kludge - force the mode line to be updated.  Is there a better
    ;; way to do this?
    (set-buffer-modified-p (buffer-modified-p))))

(defun Picture-clean ()
  "Eliminate whitespace at ends of lines."
  (save-excursion
   (goto-char (dot-min))
   (while (re-search-forward "[ \t][ \t]*$" nil t)
     (delete-region (match-beginning 0) (dot)))))
