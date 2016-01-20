
# page INTERNALS
# {{{
waitFor = (testFx, onReady, timeOutMillis=3000) ->
    start = new Date().getTime()
    condition = false
    f = ->
        if (new Date().getTime() - start < timeOutMillis) and not condition
            # If not time-out yet and condition not yet fulfilled
            condition = (if typeof testFx is 'string' then eval testFx else testFx()) #< defensive code
        else
            if not condition
                # If condition still not fulfilled (timeout but condition is 'false')
                phantom.exit(1)
            else
                # Condition fulfilled (timeout and/or condition is 'true')
                if typeof onReady is 'string' then eval onReady else onReady() #< Do what it's supposed to do once the condition is fulfilled
                clearInterval interval #< Stop this interval
    interval = setInterval f, 250 #< repeat check every 250ms


page = new WebPage()
page.viewportSize = { width: 600, height : 600 }

# for cookie control
page.resources = []
page.onResourceRequested = (req) ->
  page.resources[req.id] =
    request: req
    startReply: null
    endReply: null
page.onResourceReceived = (res) ->
  if res.stage is 'start'
    console.log res
    page.resources[res.id].startReply = res
  if res.stage is 'end'
    console.log res
    page.resources[res.id].endReply = res

# sandbox console messaging
page.onConsoleMessage = (msg) -> console.log msg

# handle page's alert()
page.onAlert = (msg) -> 
  console.log 'ALERT: "'+msg+'"'
  time = new Date().getTime()
  page.render userid+'-'+time+'-error.png'
  phantom.exit(1)

userid = phantom.args[0]
# }}}

page.open '[[ENTRY_POINT]]', (status) ->
  
  waitFor ->
    page.evaluate ->
     # 
     # -------------------- page internals, DO NOT MODIFY -------------------------------
     # {{{
     waitFor = (testFx, onReady, timeOutMillis=3000) ->
        start = new Date().getTime()
        condition = false
        f = ->
            if (new Date().getTime() - start < timeOutMillis) and not condition
                # If not time-out yet and condition not yet fulfilled
                condition = (if typeof testFx is 'string' then eval testFx else testFx()) #< defensive code
            else
                if not condition
                    # If condition still not fulfilled (timeout but condition is 'false')
                    console.log "'waitFor()' timeout"
                    phantom.exit(1)
                else
                    # Condition fulfilled (timeout and/or condition is 'true')
                    console.log "'waitFor()' finished in #{new Date().getTime() - start}ms."
                    if typeof onReady is 'string' then eval onReady else onReady() #< Do what it's supposed to do once the condition is fulfilled
                    clearInterval interval #< Stop this interval
        interval = setInterval f, 250 #< repeat check every 250ms

     
      # click element
      clickElement = (element, evtType = 'click') ->
        evt = document.createEvent("MouseEvents")
        evt.initMouseEvent(evtType, true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
        if element
          element.dispatchEvent(evt)
      
      # call for blur       
      blurElement = (element, evtType = 'blur') ->
        evt = document.createEvent('HTMLEvents')
        evt.initEvent('blur', true, true)
        if element
          element.dispatchEvent evt
   
      # fill text value
      fillText = (element, value) ->
        el = body.querySelector element
        return unless el
        el.value = value
      
      # click button
      clickButton = (element) ->
        el = body.querySelector element
        return unless el
        el.click()

      # check value
      checkValue = (element, checked) ->
        el = body.querySelector element
        el.checked = checked

      # set selected
      selectValue = (element, value) ->
        fillText element, value

      body = document.body
      # ------------------------------------------------------------------------------------------------
      # }}}
      console.log 'title1 = '+document.title
   
      # filling content
      fillText 'input[name=consumerBasic.screenName]', '[[consumerBasic.screenName]]'
      fillText 'input[name=consumerBasic.email]', '[[consumerBasic.email]]'
      fillText 'input[name=consumerBasic.retypeEmail]', '[[consumerBasic.retypeEmail]]'
      fillText 'input[name=consumerBasic.password]', '[[consumerBasic.password]]'
      fillText 'input[name=consumerBasic.retypePassword]', '[[consumerBasic.retypePassword]]'
      selectValue 'input[name=consumerBasic.secQuestion]', '[[consumerBasic.secQuestion]]'
      fillText 'input[name=consumerBasic.secAnswer]', '[[consumerBasic.secAnswer]]'
      fillText 'input[name=consumerBasic.retypeSecAnswer]', '[[consumerBasic.retypeSecAnswer]]'
      selectValue 'input[name=consumerBasic.secQuestion2]', '[[consumerBasic.secQuestion2]]'
      fillText 'input[name=consumerBasic.secAnswer2]', '[[consumerBasic.secAnswer2]]'
      fillText 'input[name=consumerBasic.retypeSecAnswer2]', '[[consumerBasic.retypeSecAnswer2]]'
      selectValue 'input[name=babyDetailsList[0].babyGender]', '[[babyDetailsList[0].babyGender]]'
      fillText 'input[name=babyDetailsList[0].babyBirthDate]', '[[babyDetailsList[0].babyBirthDate]]'
      checkValue 'input[name=MBQDetails.pregnant]', true
      checkValue 'input[name=consumerPrefrences.newsletterOptin]', true
      checkValue 'input[name=consumerPrefrences.pampersPromoOptin]', [[consumerPrefrences.pampersPromoOptin]]
      checkValue 'input[name=consumerPrefrences.pngPromoOptin]', [[consumerPrefrences.pngPromoOptin]]
      
      clickElement body.getElementById 'submitLink'

      console.log 'submitted'
      console.log 'title2 = '+document.title
      return true
  
  , ->
    # here is the page reloaded
    result = page.evaluate ->
      console.log 'title3 = '+document.title
      result = document.body.querySelector('#result').innerHTML
    
    # return 1 when error or return result text
    res = 1 #error
    res = 0 if result.length > 0
    console.log result
    phantom.exit(res)
