# -*- coding:utf-8 -*-

miquire :mui, 'skin'
miquire :addon, 'addon'
miquire :addon, 'settings'

Module.new do

  plugin = Plugin::create(:call_api_Tofav)
  
  main = Gtk::TimeLine.new()
  service = nil
  
  querybox = Gtk::Entry.new()
  querycont = Gtk::VBox.new(false, 0)
  searchbtn = Gtk::Button.new('ふぁぼ候補')
  
  searchbtn.signal_connect('clicked'){ |elm|
    favnum = 10
    #ファイルから読み込んでみるよ
    begin
      text = []
      open("../plugin/favnums.txt") do |file|
        file.each do |read|
          text << read.chomp!
        end
      end
      favnum = text[1]
    rescue
      #読み込みが失敗したら10個だけ検索してふぁぼるよ
    end
    
    Gtk::Lock.synchronize{
      elm.sensitive = querybox.sensitive = false
      main.clear
      #テキストボックスが空なら何もしないよ
      if querybox.text.size > 0 then
        screen_name = querybox.text
        user = User.findbyidname("#{screen_name}", true)
        user[:id] if user
        service.call_api(:user_timeline, :user_id => user[:id],
                         :no_auto_since_id => true,
                         :count => favnum.to_i){ |res|
          Gtk::Lock.synchronize{
            res.each do |mes|
              unless mes.favorite? || mes.retweet?
                #ふぁぼふぁぼするよ
                mes.favorite(true)
                main.add(mes)
              end
            end
            #応答を復活させるよ
            elm.sensitive = querybox.sensitive = true
          } 
        }
      else 
        # => 応答を復活させるよ
        querybox.sensitive = true
        elm.sensitive = true
      end
    } 
  }
  
  querycont.closeup(Gtk::HBox.new(false, 0).pack_start(querybox).closeup(searchbtn))
  
  plugin.add_event(:boot){ |s|
    service = s
    container = Gtk::VBox.new(false, 0).pack_start(querycont, false).pack_start(main, true)
    Plugin.call(:mui_tab_regist, container, 'Call_Api_ToFav', MUI::Skin.get("etc.png"))
    #同梱のtarget.pngをskin/data
    #に置いた時は上をコメントアウトしてこちらをお使いください
    #Plugin.call(:mui_tab_regist, container, 'Call_Api_ToFav', MUI::Skin.get("target.png"))

  }
  
end
