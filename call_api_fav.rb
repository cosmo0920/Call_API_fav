# -*- coding:utf-8 -*-

#遅延ふぁぼを有効(true)|無効(false)にします
#有効にするとmikutterが重くなる可能性があります
$is_sleep = false

def xorshift128_sleep(stime)
  x = 123456789; y = 362436069; z = 521288629; w = 88675123
  t = 0
  x = Time.now.to_i
  t = x ^ (x << 11)
  x = y; y = z; z = w
  w = (w ^ (w >> 19)) ^ (t ^ (t >> 8))
  sleep(rand(stime.to_i)+ (w%10).to_i)
end

Plugin.create(:call_api_fav) do

  querybox = Gtk::Entry.new()
  searchbtn = Gtk::Button.new('ふぁぼ候補')

  tab(:call_api_fav, 'Call_Api_ToFav') do
    set_icon MUI::Skin.get("etc.png")
    shrink
    nativewidget Gtk::HBox.new(false, 0).pack_start(querybox).closeup(searchbtn)
    expand
    timeline :call_api_fav
  end

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
    
    timeline(:call_api_fav).clear
    #テキストボックスが空なら何もしないよ
    if querybox.text.size > 0 then
      screen_name = querybox.text
      user = User.findbyidname("#{screen_name}", true)
      user[:id] if user
      Service.primary.call_api(:user_timeline, :user_id => user[:id],
                               :no_auto_since_id => true,
                               :count => favnum.to_i){ |res|
        timeline(:call_api_fav) << res
        res.each do |mes|
          unless mes.favorite? || mes.retweet?
            if $is_sleep == true then
              @threadFav = SerialThreadGroup.new
              @threadFav.new{
                #ふぁぼふぁぼするよ
                sleep(xorshift128_sleep(stime))
                mes.favorite(true)
              }
            else
              @threadFav = SerialThreadGroup.new
              @threadFav.new{
                #ふぁぼふぁぼするよ
                mes.favorite(true)
              }
            end
          end
        end
      }
    end
  }
end
