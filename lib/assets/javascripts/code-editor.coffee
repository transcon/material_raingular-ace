angular.factories
  .directive 'codeEditor', ($timeout)->
    restrict: 'E'
    replace: true
    template: (element,attributes) ->
      '<span><div id="process-code-editor"></div><input type="hidden" ng-update="' + attributes.ngModel + '"</span>'
    link: (scope, element, attributes)->
      ace.config.set("basePath","/assets/ace")
      editor = ace.edit("process-code-editor")
      editor.setTheme("ace/theme/monokai")
      editor.getSession().setMode("ace/mode/ruby")
      editor.getSession().setTabSize(2)
      editor.getSession().setUseSoftTabs(true)
      span = angular.element(document.getElementById('process-code-editor'))
      heights = []
      e = element[0].parentElement.parentElement
      while e
        heights.push(e.offsetHeight) unless e.offsetHeight == 0
        e = e.parentElement
      angular.element(window).on 'resize', (event)->
        span.css('height',heights.min() + 'px')
      span.css('fontSize', '14px').css('height',heights.min() + 'px')
      model  = attributes.ngModel
      scopes = model.split('.')
      model  = scopes.pop()
      parent = scope
      for mod in scopes
        parent = parent[mod]
      if parent
        editor.setValue(parent[model])
      else
        watcher = scope.$watch scopes.join('.'), (newVal) ->
          if newVal
            parent = scope
            for mod in scopes
              parent = parent[mod]
            editor.setValue(parent[model])
            watcher()
      element.find('textarea').bind 'keyup', ->
        $timeout.cancel(scope.debounce)
        scope.debounce = $timeout ->
          parent[model] = editor.getValue()
          scope.$apply(element.find('input')[0].attributes['ng-change'].value)
        ,750
