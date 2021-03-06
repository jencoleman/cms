require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"
require "redcarpet"

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    render_markdown(content)
  end
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end
  erb :index
end

post "/edit/:filename/update" do
  file_path = File.join(data_path, params[:filename])
  new_content = params["new_content"]
  
  File.write(file_path, new_content)
  session[:message] = "#{params[:filename]} has been updated."
  redirect "/"
end

get "/:filename" do
  file_path = File.join(data_path, params[:filename])
  
  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{params[:filename]} does not exist."
    redirect "/"
  end
end

get "/edit/:filename" do
  file_path = File.join(data_path, params[:filename])
  
  @current_content = File.read(file_path)
  erb :edit
end


