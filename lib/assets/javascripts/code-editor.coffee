# //= require ace/theme-ambiance.js
# //= require ace/theme-crimson_editor.js
# //= require ace/theme-github.js
# //= require ace/theme-iplastic.js
# //= require ace/theme-kuroir.js
# //= require ace/theme-monokai.js
# //= require ace/theme-solarized_light.js
# //= require ace/theme-textmate.js
# //= require ace/theme-twilight.js
# //= require ace/theme-vibrant_ink.js

# //= require ace/mode-ruby
# //= require ace/mode-coffee
# //= require ace/mode-sass
# //= require ace/mode-less
# In order to have digested assets function properly, theme and mode must be required up front
editor_theme = "ambiance"
# editor_theme = "crimson_editor"
# editor_theme = "github"
# editor_theme = "iplastic"
# editor_theme = "kuroir"
# editor_theme = "monokai"
# editor_theme = "solarized_light"
# editor_theme = "textmate"
# editor_theme = "twilight"
# editor_theme = "vibrant_ink"

class EditorHeight
  constructor: (scope,element,attributes)->
    @scope      = scope
    @element    = element
    @attributes = attributes

  minHeight: ->
    heights = []
    e = @element[0].parentElement.parentElement
    while e
      heights.push(e.offsetHeight) unless e.offsetHeight == 0
      e = e.parentElement

  height: ->
    return @minHeight() + 'px' unless @attributes.editorSize
    raw_equation = @attributes.editorSize.replace /[\+\-\/\*]/g, (operator)->
      return " " + operator + " "
    equation = []
    for el in raw_equation.split(/\s+/)
      unless el.match(/(^[\d+]?[.]?[\d+]$)|[\+\-\/\*]/)
        method = 'getElement' + if el[0] == "#" then 'ById' else 'sByClass'
        equation.push document[method](el[1..-1]).offsetHeight
      else
        equation.push(el)
    return @scope.$eval(equation.join(' ')) + 'px'

angular.module('materialRaingularAce', [])
  .directive 'codeEditor', ($timeout, factoryName, $injector)->
    restrict: 'E'
    replace: true
    require: 'ngModel'
    template: (element,attributes) ->
      websocketHelper = ->
        if typeof attributes.webSocket == 'undefined' then 'update' else 'model'
      '<span><div></div><input type="hidden" ng-' + websocketHelper + '="' + attributes.ngModel + '"</span>'
    link: (scope, element, attributes, modelCtrl)->
      exitStatus = true
      while exitStatus
        uniqueId   = Math.floor(Math.random()*(1000000))
        exitStatus = !!document.getElementById(uniqueId)
      id = attributes.ngModel.replace('.','-') + "-code-editor-" + uniqueId
      element[0].getElementsByTagName('div')[0].setAttribute('id',id)
      angular.ace = {} unless angular.ace
      editor = ace.edit(id)
      mode = attributes.codeType || 'ruby'
      editor.getSession().setUseWorker(false)
      editor.setTheme("ace/theme/" + editor_theme)
      editor.getSession().setMode("ace/mode/" + mode)
      editor.getSession().setTabSize(2)
      editor.getSession().setUseSoftTabs(true)
      editor.$blockScrolling = Infinity
      angular.ace[id] = editor
      span = angular.element(document.getElementById(id))
      editorHeight = new EditorHeight(scope,element,attributes)
      angular.element(window).on 'resize', (event)->
        span.css('height',editorHeight.height())
        editor.resize()
      span.css('fontSize', '14px').css('height',editorHeight.height())
      editor.setValue(scope.$eval(attributes.ngModel),-1) unless typeof scope.$eval(attributes.ngModel) == 'undefined'
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
