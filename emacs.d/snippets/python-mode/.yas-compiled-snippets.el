;;; Compiled snippets and support files for `python-mode'
;;; Snippet definitions:
;;;
(yas-define-snippets 'python-mode
                     '(("qw" "\"${1:string}\".split()" "qw(...)" nil nil nil "/home/vifon/.emacs.d/snippets/python-mode/qw" nil nil)
                       ("open" "with open(${1:path}, '${2:r}') as ${3:name}:\n    $0" "with open(..., ...) as ...:" nil nil nil "/home/vifon/.emacs.d/snippets/python-mode/open" nil nil)
                       ("doctest" "import doctest\nimport sys\nsys.exit(doctest.testmod()[0])" "doctest" nil nil nil "/home/vifon/.emacs.d/snippets/python-mode/doctest" nil nil)
                       ("bp" "import pdb\npdb.set_trace()" "breakpoint" nil nil nil "/home/vifon/.emacs.d/snippets/python-mode/breakpoint" nil nil)
                       ("argparser" "${1:parser} = argparse.ArgumentParser()\n$1.add_argument($0)\n${2:args} = $1.parse_args()" "parser = argparse.ArgumentParser()" nil nil nil "/home/vifon/.emacs.d/snippets/python-mode/argparser" nil nil)))


;;; Do not edit! File generated at Thu Apr 25 00:56:11 2019
