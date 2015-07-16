angular.module('materialRaingularAce', [])
  .directive 'codeEditor', ($timeout)->
    restrict: 'E'
    replace: true
    require: 'ngModel'
    template: (element,attributes) ->
      '<span><div id="process-code-editor"></div><input type="hidden" ng-update="' + attributes.ngModel + '"</span>'
    link: (scope, element, attributes, modelCtrl)->
      ace.config.set("basePath","/assets/ace")
      editor = ace.edit("process-code-editor")
      editor.setTheme("ace/theme/monokai")
      editor.getSession().setMode("ace/mode/ruby")
      editor.getSession().setTabSize(2)
      editor.getSession().setUseSoftTabs(true)
      editor.$blockScrolling = Infinity
      span = angular.element(document.getElementById('process-code-editor'))
      heights = []
      e = element[0].parentElement.parentElement
      while e
        heights.push(e.offsetHeight) unless e.offsetHeight == 0
        e = e.parentElement
      angular.element(window).on 'resize', (event)->
        span.css('height',heights.min() + 'px')
      span.css('fontSize', '14px').css('height',heights.min() + 'px')
      scope.$watch attributes.ngModel, (newVal, oldVal) ->
        unless newVal == editor.getValue()
          if newVal && oldVal
            dmp = new diff_match_patch()
            offset = 0
            doc = editor.session.doc
            Range  = ace.require('ace/range').Range
            for section in dmp.diff_main(oldVal, newVal,true)
              [op,text] = section
              if (op == 0)
                offset += text.length
              else if (op == -1)
                doc.remove Range.fromPoints(doc.indexToPosition(offset), doc.indexToPosition(offset + text.length))
              else if (op == 1)
                doc.insert(doc.indexToPosition(offset), text)
                offset += text.length
          else
            editor.setValue(modelCtrl.$modelValue,-1)
      element.find('textarea').bind 'keyup', ->
        $timeout.cancel(scope.debounce)
        scope.debounce = $timeout ->
          modelCtrl.$setViewValue(editor.getValue())
          scope.$apply(element.find('input')[0].attributes['ng-change'].value)
        ,750
