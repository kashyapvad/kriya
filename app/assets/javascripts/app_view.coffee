extractURL = (textval) ->
  urlRegex = /\b((?:https?:\/\/|www\d{0,3}[.])(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s\`!()\[\]{};:\'\".,<>?«»“”‘’]))/img
  urlFinal = ''
  textval.replace(urlRegex, (url) -> urlFinal = url)
  urlFinal

AppView = {
  initialize: ->
    $(document).on "change", "#user_gender_female", @setFemaleAvatar
    $(document).on "change", "#user_gender_male", @setMaleAvatar
    $(document).on "keyup", "#post_body", @scrapeUrl
    $(document).on "click", ".filepicker", @pickFile
    $(document).on "click", "[data-modal]", @openModal
    document.addEventListener "turbolinks:before-cache", @preparePageForTurbolinks

    @initComponents()
    @initSemanticUI()
    @initChat()

  pickFile: (e) ->
    e.preventDefault()
    options = {}
    $el = $(e.target)

    dimension = $el.data("dimension")
    if dimension
      options.cropDim = [parseInt(dimension.split(',')[0]), parseInt(dimension.split(',')[1])]

    filepicker.pick(options, (Blob) ->
      $el.parent().find("img").attr("src", Blob.url)
      $el.parent().find("input[type=hidden]").val(Blob.url)
    )

  openModal: (e) ->
    console.log 'opening modal'
    e.preventDefault()
    modal_id = $(this).data('modal')
    $("[data-modal-id=#{modal_id}]").modal('show')

  initSemanticUI: ->
    $('.ui.sidebar').sidebar('attach events', '.sidebar-toggle')
    $('.ui.checkbox').checkbox()
    $('.ui.rating').rating()
    $('.ui.dropdown').dropdown()
    $('.ui.form').form(
      fields:
        email:
          identifier  : 'email',
          rules: [{
              type   : 'empty',
              prompt : 'Please enter your e-mail'
            },{
              type   : 'email',
              prompt : 'Please enter a valid e-mail'
            }]
        password:
          identifier  : 'password',
          rules: [{
              type   : 'empty',
              prompt : 'Please enter your password'
            },{
              type   : 'length[6]',
              prompt : 'Your password must be at least 6 characters'
            }]
    )

  initChat: (target='#my-chat') ->
    if $(target).length > 0
      name = $(target).data("name")
      new Chat({
        greeting: [
          "Hi #{name}!"
          'Welcome to Goomp.'
          'We are so excited to have you here.'
          'Goomp is still in beta, so feel free to create a goomp or join existing ones!'
          {
            type: 'visit',
            answers: [{
              'text': 'Create Goomp',
              'path': '/goomps/new'
            },
            {
              'text': 'Explore Goomps',
              'path': '/goomps'
            }]
          }
        ],

        tellmemore: [
          'I feel humbled. 🙂',
          '<form accept-charset="UTF-8" action="/goomps" class="ui form" method="post"><input name="_csrf_token" type="hidden" value="QVsIEyUncyURU2dFfRowT3hxCDMtAAAA2+jvPhKdI0/72wd554JaBQ=="><input name="_utf8" type="hidden" value="✓"><div class="center aligned field"><div class="center aligned field"><img id="user-avatar" src="/images/default-male.png"></div><a class="filepicker ui primary button" data-dimension="1500,500">Upload Goomp Cover</a><input id="goomp_cover" name="goomp[cover]" type="hidden" value="/images/default-male.png"></div><div class="field"><label for="goomp_name">Name</label><input id="goomp_name" name="goomp[name]" type="text"></div><div class="field"><label for="goomp_description">Description</label><input id="goomp_description" name="goomp[description]" type="text"></div><input class="ui primary button" type="submit" value="Save"></form>',
          {
            type: 'choose',
            answers: [{
              'text': 'Which companies?',
              'path': 'companies'
            },
            {
              'text': 'You write?!',
              'path': 'write'
            }]
          }
        ],

        'simple-bye': [
          'Alright! It was great talking to you! Enjoy!'
        ],

        'companies-realwork': [
          'Hah!',
          'Writing and speaking is part of my job. It gives me a broader perspective and helps me solve problems.',
          'If you happen to be on Twitter, we should totally <a target="_blank" href="https://twitter.com/azumbrunnen_">talk</a> btw!',
          'You can also drop me a message here and I\'ll get back to you asap. Otherwise, I\'ll let you browse my website for a little bit.',
          {
            type: 'choose',
            answers: [{
              'text': 'Let\'s talk!',
              'path': 'contact'
            },
            {
              'text': 'I\'ll browse a little...',
              'path': 'simple-bye'
            }]
          }
        ],
        'companies': [
          'Here are some of the companies I\'ve worked with, both on staff and as an independent freelancer',
          '- Google<br>- iA<br>- Hinderling Volkart<br>- Red Bull<br>- The Guardian<br>',
          {
            type: 'choose',
            answers: [{
              'text': 'Cool. What did you do for them?',
              'path': 'portfolio'
            }]
          }
        ],


        'portfolio': [
          'I\'m happy to talk about it over coffee. What do you think?',
          {
            type: 'choose',
            answers: [{
              'text': 'Cool! ☕️',
              'path': 'contact-coffee'
            },
            {
              'text': 'Nah... 😑',
              'path': 'portfolio-nah'
            }]
          }
        ],
        'portfolio-nah': [
          'Alright... I understand. Coffee is not for everyone. How about tea then?',
          {
            type: 'choose',
            answers: [{
              'text': 'Ok, sure!',
              'path': 'contact'
            },
            {
              'text': 'Nah... 😒',
              'path': 'portfolio-nah-nah'
            }]
          }
        ],
        'portfolio-nah-nah': [
          'Seems like we don\'t have so much in common. That\'s ok! Working with different individuals is incredibly enriching.',
          'I suggest you drop me a line and I promise to get back to you asap! Cool?',
          {
            type: 'choose',
            answers: [{
              'text': 'Ok, sure!',
              'path': 'contact'
            },
            {
              'text': 'Nah... 😒!!',
              'path': 'hard-to-convince'
            }]
          }
        ],

        'hard-to-convince': [
          'Hmm... good chat! Maybe a little more about me... I like traveling and long walks on the beach.',
          'Speaking of beaches... I just came back from speaking Tel-Aviv. There was a great conference there.',
          'Mike Monteiro ended up fighting a robot on stage!',
          '<iframe border=0 frameborder=0 height=250 width=550 src="http://twitframe.com/show?url=https%3A%2F%2Ftwitter.com%2Fuxsalon%2Fstatus%2F722550897377677312"></iframe>',
          'Are you perhaps UX field too?',
          {
            type: "choose",
            answers: [{
              'text': 'Yes...',
              'path': 'uidesigner'
            },{
              'text': 'No!',
              'path': 'uidesigner-no'
            }]
          }
        ],

        'uidesigner-no': [
          'Interesting... I appreciate your interest in design.',
          'By the way, you should check out my friend Siri! She\'s hilarious. I think you guys would get along!',
          'Alright, gotta to run to a meeting now. Feel free to leave me a message! I\'ll read it asap.',
          {
            type: 'write',
            path: 'contact'
          }
        ],

        'uidesigner-yes': [
          'Hah! I thought so!',
          'If you come back here another time, I\'ll promise I\'ll share great UX articles with you! It was a pleasure talking to you!',
          'See you in a bit!',
        ],


        'contact': [
          'Great! I\'m looking forward to it!',
          'Let me know what\'s on your mind and I\'ll get back to you asap!',
          {
            type: 'write',
            path: 'contact-thanks'
          }
        ],
        'contact-coffee': [
          'Great! Nothing beats UX and coffee!',
          'What specifically did you want to discuss?',
          {
            type: 'write',
            path: 'contact-thanks'
          }
        ],
        'contact-thanks': [
          'I\'m intrigued! Thanks! I just need your email so I can get back to you!',
          {
            type: 'write',
            path: 'contact-verify-email',
          }
        ],
        'contact-verify-email': [
          'That\'s one beautiful email address! I\'ll get back to you as soon as possible.',
          'Meanwhile, you can scroll down and check my website or go to <a href="http://www.google.com">Google.com</a> and try pressing the "I feel lucky" button. It might be your lucky day!',
          'Talk to you soon! :)',
        ],


        write: [
          'Yes! I strongly believe that writing helps me be a better designer. You can check out some of my most popular articles:',
          '- <a target="_blank" href="https://medium.com/swlh/the-illusion-of-time-8f321fa2f191">The Illusion of Time</a><br>'+
          '- <a target="_blank" href="https://www.smashingmagazine.com/2013/10/smart-transitions-in-user-experience-design/">Smart Transitions in UI Design</a><br>'+
          '- <a target="_blank" href="http://azumbrunnen.me/blog/creating-distraction-free-reading-experiences/">Creating distraction-free reading experiences</a><br>',
          {
            type: "choose",
            answers: [{
              'text': 'What about speaking?',
              'path': 'speaking'
            },{
              'text': 'Let\'s talk!',
              'path': 'contact'
            }]
          }
        ],

        speaking: [
          'I love sharing ideas and meeting new people. I occasionally speak at UX conferences about design.',
          'Just recently, I talked about researching as a freelancer at UX Salon:',
          '<iframe width="420" height="315" src="https://www.youtube.com/embed/HVr4Cw1BPBc" frameborder="0" allowfullscreen></iframe>',
          'A great event. If you ever happen to go to Tel-Aviv, make sure you try the Shakshuka! 🍲',
          {
            type: "choose",
            answers: [{
              'text': 'Cool. Do you work too?',
              'path': 'companies-realwork'
            }]
          }
        ]
      }, {
        targetNode: target
      })

  setFemaleAvatar: ->
    url = "/images/default-female.png"
    val = $("#user_picture").val()
    if val == "/images/default-male.png"
      $("#user-avatar").attr("src", url)
      $("#user_picture").val(url)

  setMaleAvatar: ->
    url = "/images/default-male.png"
    val = $("#user_picture").val()
    if val == "/images/default-female.png"
      $("#user-avatar").attr("src", url)
      $("#user_picture").val(url)

  scrapeUrl: (e) ->
    e.stopPropagation()
    text = $("#post_body").val()
    $form = $("#post_body").parents("form")

    url = extractURL(text)

    if url.length > 0
      text = text.replace(url, '')
      $("#post_body").val(text)
      csrf = $("input[name=_csrf_token]").val()
      $.ajax(
        url: "/scrapes"
        type: "post"
        data:
          url: url
        headers:
          "X-CSRF-TOKEN": csrf
        dataType: "json",
        success: (resp) ->
          link = resp.data
          console.log 'suc', link
          $("#post_link_title", $form).val link.title
          $("#post_link_description", $form).val link.description
          $("#post_link_url", $form).val link.url
        error: (resp) ->
          link = resp.data
          console.log 'err', link
      )

  initComponents: ->
    filepicker.setKey("Akt6oZj2YRamLQYtKyrhzz")

  preparePageForTurbolinks: ->
    # Make sure chat board is clear if user go back
    $("#my-chat").html "" if $("#my-chat").length > 0
}

document.addEventListener "turbolinks:load", ->
  AppView.initialize()
