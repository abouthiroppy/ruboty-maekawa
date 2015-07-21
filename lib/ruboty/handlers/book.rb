require "calil"

module Ruboty
    module Handlers
        class Book < Base
            BORDER_STR = '============================================================'

            on(
                /book/,
                all: false,
                name: "book",
                description: "Maekawa Librarian\n\texample: @maekawa book title:機械学習. creator:松尾."
            )

            def book(message)
                begin
                    query = message.body.sub("#{message.robot.name} book ", '').strip

                    if query.length == 0
                        raise
                    end

                    hash = {}
                    query.split(".").each { |tag|
                        tag.strip!
                        kv = tag.split(":")
                        if kv.length <= 1
                            raise
                        end

                        key = kv[0]
                        values = kv[1]
                        hash[key] = []
                        values.split(",").each { |v|
                            hash[key] << v
                        }
                    }

                    if hash.key?('title') == false
                        raise "no_title"
                    end
                rescue Exception => e
                    if e.to_s == "no_title"
                        message.reply("タイトルぐらい入力してほしいにゃ")
                    else
                        message.reply("構文エラーにゃ\nhelpでも見るにゃ")
                    end
                    return
                end

                if (2 <= hash['title'].length)
                    connector_type = Ruboty::Maekawa::Searcher::CONNECTOR_OR
                    hash = { title: hash['title'] }
                else
                    connector_type = Ruboty::Maekawa::Searcher::CONNECTOR_AND
                end

                hash['mediatype'] = 1
                message.reply("このクエリで調べるにゃ\n#{hash.inspect}")

                books = Ruboty::Maekawa::Searcher.request(connector_type, hash)

                books.map! do |book|
                    next if book.isbn.empty?
                    book
                end

                if books.length == 0
                    message.reply("見つからなかったにゃ〜")
                    return
                end

                title_str = ''
                isbns = []
                books.each do |book|
                    title_str += "- #{book.title}\n"
                    isbns << book.isbn
                end
                message.reply("検索結果にゃ\n#{title_str}\n大学図書館にあるかどうか調べるにゃ\n#{BORDER_STR}")

                results = ''
                calil_books = Calil::Book.find(isbns, %w(Univ_Aizu))
                calil_books.each.with_index(0) { |cbook, i|
                    libaizu = cbook.systems[0]
                    next if (libaizu.reserveurl.nil? || libaizu.reserveurl.empty?)

                    results += "- #{books[i].title}\n  #{libaizu.libkeys.inspect}"
                }
                message.reply("#{results}\n#{BORDER_STR}\n大学にあるのはこのぐらいみたいだにゃ")
            end
        end
    end
end
