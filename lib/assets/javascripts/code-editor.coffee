# //= require ace/theme-monokai
# //= require ace/mode-ruby
# In order to have digested assets function properly, theme and mode must be required up front
angular.module('materialRaingularAce', [])
  .directive 'codeEditor', ($timeout, factoryName, $injector)->
    restrict: 'E'
    replace: true
    require: 'ngModel'
    template: (element,attributes) ->
      websocketHelper = ->
        if typeof attributes.webSocket == 'undefined' then 'update' else 'model'
      '<span><div id="process-code-editor"></div><input type="hidden" ng-' + websocketHelper + '="' + attributes.ngModel + '"</span>'
    link: (scope, element, attributes, modelCtrl)->
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
      updateFunc = ->
        modelCtrl.$setViewValue(editor.getValue())
        unless typeof attributes.webSocket != 'undefined'
          scope.$apply(element.find('input')[0].attributes['ng-change'].value)
          console.dir 'hello'
        else
          parent      = attributes.ngModel.split('.')
          modelName   = parent.pop()
          parent_name = parent.join('.')
          parent      = scope.$eval(parent_name)
          list        = $injector.get(factoryName(parent_name))
          params      = {id: parent.id, suppress: true}
          params[parent_name] = {}
          params[parent_name][modelName] = parent[modelName]
          list.update params
      element.find('textarea').bind 'keyup', ->
        $timeout.cancel(scope.debounce)
        scope.debounce = $timeout ->
          updateFunc() unless editor.getValue() == modelCtrl.$viewValue
        ,750
