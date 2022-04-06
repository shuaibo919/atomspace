;
; deep-space-test.scm
; Assorted tests of change-sets in the atomspace.
;
(use-modules (srfi srfi-1))
(use-modules (opencog) (opencog test-runner))

(opencog-test-runner)

; -------------------------------------------------------------------
; Common setup, used by all tests.
; Creates a stack of AtomSpaces, each a child of the last.

(define base-space (cog-atomspace))

; Create a list of atomspaces, each a child of the last.
(define (make-space-list LST NUM)
	(if (<= NUM 0) LST
		(let ((newspace (cog-new-atomspace (cog-atomspace))))
			(cog-set-atomspace! newspace)
			(make-space-list (cons newspace LST) (- NUM 1)))))

; Twenty of them, the base space first in the list.
(define space-list (reverse (make-space-list (list base-space) 20)))

; -------------------------------------------------------------------
; Test to make sure that the created AtomSpace appar in a stack.

(define astack "verify AtomSpace stack")
(test-begin astack)

; Go back to the begining.
(cog-set-atomspace! base-space)
(define curr-space base-space)

(for-each (lambda (space)
		(test-equal "space-env-size" 1 (length (cog-atomspace-env space)))
		(test-equal "space-parent" curr-space (car (cog-atomspace-env space)))
		(set! curr-space (car (cog-atomspace-env space)))
	)
	space-list)
(test-end astack)

; -------------------------------------------------------------------
; Test to make sure that the same Atom in each AtomSpace has the
; correct value on that Atom.

(define vstack "simple value stack")
(test-begin vstack)

; Create on Atom, with different truth values in each space.
(define cnt 0)
(for-each (lambda (space)
		(cog-set-atomspace! space)
		(Concept "hello" (ctv 1 0 cnt))
		(set! cnt (+ 1 cnt)))
	space-list)

; Now verify that the values are as expected.
(set! cnt 0)
(for-each (lambda (space)
		(cog-set-atomspace! space)
		; (format #t "Expect: ~A Got: ~A\n" cnt
      ;   (cog-tv-count (cog-tv (Concept "hello"))))

		; The Atom should belong to this specific atomspace
		(test-equal "membership" space
			(cog-atomspace (cog-node 'Concept "hello")))

		(test-equal "count-tv" cnt
			(inexact->exact (cog-tv-count (cog-tv (cog-node 'Concept "hello")))))

		; Each atomspace should contain just one atom.
		(test-equal "atomspace-size" 1 (count-all))
		(set! cnt (+ 1 cnt)))
	space-list)

(test-end vstack)

; -------------------------------------------------------------------
; Check that the IncomingSet behaves as expected.

(define istack "simple incoming stack")
(test-begin istack)

; Make sure that there is a Concept "foo" in the base space.
(cog-set-atomspace! base-space)
(Concept "foo")

(for-each (lambda (space)
		(cog-set-atomspace! space)

		; The Atom should belong to this specific atomspace
		(test-equal "membership" space
			(cog-atomspace (cog-node 'Concept "hello")))

		(test-equal "atomspace-size" 2 (count-all))
	)
	space-list)

; Create a bunch of Links
(set! cnt 0)
(for-each (lambda (space)
		(cog-set-atomspace! space)
(format #t "yo ~A\n" (cog-atomspace (cog-node 'Concept "foo")))
		(cog-set-tv! (List (Concept "hello") (Concept "foo"))
			(CountTruthValue 1 0 (* cnt 2)))
(format #t "da ~A\n" (cog-atomspace (Concept "foo")))
		(set! cnt (+ 1 cnt)))
	space-list)

; Now verify that the values are as expected
(set! cnt 0)
(for-each (lambda (space)
		(cog-set-atomspace! space)
		; (format #t "Expect: ~A Got: ~A\n" cnt
      ;   (cog-tv-count (cog-tv (Concept "hello"))))

		(test-equal "count-tv" cnt
			(inexact->exact (cog-tv-count (cog-tv (Concept "hello")))))

		; Each atomspace should contain just three atoms.
		(test-equal "atomspace-size" 3 (count-all))
		(test-equal "incoming-size" 1 (cog-incoming-size (cog-node 'Concept "foo")))
		(test-equal "incoming-size" 1 (cog-incoming-size (Concept "hello")))

		; Verify correct membership of the Atoms.
		(test-equal "membership-hello" space
			(cog-atomspace (Concept "hello")))

(format #t "base: ~A\n" (cog-atomspace (cog-node 'Concept "foo")))
		(test-equal "membership-foo" base-space
			(cog-atomspace (Concept "foo")))

		(test-equal "membership-link" space
			(cog-atomspace (car (cog-incoming-set (Concept "hello")))))

		; The incoming sets should be equal.
		(test-equal
			(cog-incoming-set (Concept "hello"))
			(cog-incoming-set (Concept "foo")))

		; Values on the link should be correct
		(test-equal "list-tv" (* 2 cnt)
			(inexact->exact (cog-tv-count (cog-tv
				(car (cog-incoming-set (Concept "foo")))))))

		(set! cnt (+ 1 cnt)))
	space-list)

(test-end istack)

; -------------------------------------------------------------------
(opencog-test-end)
