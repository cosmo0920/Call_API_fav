# -*- coding:utf-8 -*-

miquire :mui, 'skin'
miquire :addon, 'addon'
miquire :addon, 'settings'

#遅延ふぁぼを有効(true)|無効(false)にします
#有効にするとmikutterが重くなる可能性があります
$is_sleep = true

def xorshift128_sleep(stime)
  x = 123456789; y = 362436069; z = 521288629; w = 88675123
  t = 0
  x = Time.now.to_i
  t = x ^ (x << 11)
  x = y; y = z; z = w
  w = (w ^ (w >> 19)) ^ (t ^ (t >> 8))
  sleep(rand(stime.to_i)+ (w%10).to_i)
end

def sleep_favs(res,stime)
  for mes in res
    unless mes.favorite? || mes.retweet?
    @threadFav = SerialThreadGroup.new
      @threadFav.new{
        sleep(xorshift128_sleep(stime))
        mes.favorite(true)
     }
    end
  end
end

def favs(res)
  res.each do |mes|
    unless mes.favorite? || mes.retweet?
      @threadFav = SerialThreadGroup.new
      @threadFav.new{
        #ふぁぼふぁぼするよ
        mes.favorite(true)
      }
    end
  end
end

Module.new do
  
  plugin = Plugin::create(:call_api_Tofav)
  
  main = Gtk::TimeLine.new()
  service = nil
  
  querybox = Gtk::Entry.new()
  querycont = Gtk::VBox.new(false, 0)
  searchbtn = Gtk::Button.new('ふぁぼ候補')
  
  searchbtn.signal_connect('clicked'){ |elm|
    favnum = 10
    stime = 1
    #ファイルから読み込んでみるよ
    begin
      text = []
      open("../plugin/favnums.txt") do |file|
        file.each do |read|
          text << read.chomp!
        end
      end
      favnum = text[1] #ふぁぼ数の設定
      stime = text[2] #遅延時間の設定(sec.)
    rescue
      #読み込みが失敗したら1〜10秒の遅延で10個だけふぁぼるよ
    end
    
    main.clear
    #テキストボックスが空なら何もしないよ
    if querybox.text.size > 0 then
      screen_name = querybox.text
      user = User.findbyidname("#{screen_name}", true)
      user[:id] if user
      service.call_api(:user_timeline, :user_id => user[:id],
                       :no_auto_since_id => true,
                       :count => favnum.to_i){ |res|
        Delayer.new{
          main.add(res)
		}
        res.each do |mes|
          unless mes.favorite? || mes.retweet?
            if $is_sleep == true then
              sleep_favs(res,stime)
            else
              favs(res)
            end
          end
        end
      }
    end
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
