$ ->
  isUser = $("#is_user").val();
  setTimeout =>
    channelArray = []
    $( "#tasks > a" ).each((index) ->
      val = this.href.split('/').pop()
      channelArray.push parseInt(val) if parseInt(val)
    )

    for num in channelArray
      App.cable.subscriptions.create channel: "RoomChannel", room:"#{num}",
        collection: -> $("#messages")

        connected: (data) ->
          # Called when the subscription is ready for use on the server
          $('a[href="/tasks/'+@collection().data('room-id')+'"] > div.unread_message_number').text('')
          setTimeout =>
            @followCurrentMessage()
          , 1000

        received: (data) ->
          # Called when there's incoming data on the websocket for this channel
          if isUser == data.is_user
            identifier = JSON.parse this.identifier
            room_id = identifier.room
            if (@collection().data('room-id') == data.room_id) && (@collection().data('room-id') == parseInt room_id)
              $('#messages').append(data.message)
              $('#messages #chat-bot').text('')
              $('#messages').imagesLoaded ->
                ChatWindow.update()
                $(document).trigger('message:added')
                $("#messages").data("has-new-message", true)
                $(".ui.progress").hide()
            else
              count = $('a[href="/tasks/'+room_id+'"]').val()
              if count == ''
                 $('a[href="/tasks/'+room_id+'"]').val(1)
               else
                 $('a[href="/tasks/'+room_id+'"]').val(parseInt(count)+1)
              $('a[href="/tasks/'+room_id+'"] > div.unread_message_number').removeClass("ui teal left pointing label").addClass("ui teal left pointing label")
              $('a[href="/tasks/'+room_id+'"] > div.unread_message_number').text($('a[href="/tasks/'+room_id+'"]').val())
              $.cookie(room_id, $('a[href="/tasks/'+room_id+'"]').val());
        followCurrentMessage: ->
          identifier = JSON.parse this.identifier
          room_id = identifier.room
          @perform "follow", id: "#{room_id}"
  , 1000
