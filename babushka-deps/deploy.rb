dep 'on deploy', :old_id, :new_id, :branch, :env do
  requires 'build with pith.task'
end

dep 'build with pith.task' do
  run {
    shell "pith -i site/ -o public/ build"
  }
end
