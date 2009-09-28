require 'Qt'
require 'package'
require 'logging'
include Logging

class PackageTable < Qt::TableWidget
  def initialize(parent = nil)
    super(parent)

    populate_table
    
    setSizePolicy(Qt::SizePolicy.new(Qt::SizePolicy::Fixed, Qt::SizePolicy::Expanding))
    setSelectionMode(Qt::AbstractItemView::SingleSelection)
    setSelectionBehavior(Qt::AbstractItemView::SelectRows)
  end

  def populate_table
    setRowCount($packages.values.count)
    setColumnCount(2)
    setHorizontalHeaderItem(0, Qt::TableWidgetItem.new("Packages"))
    setHorizontalHeaderItem(1, Qt::TableWidgetItem.new("Installed?"))

    row = 0
    for package in $packages.values
      setItem(row, 0, Qt::TableWidgetItem.new(package.name.to_s))
      setItem(row, 1, Qt::TableWidgetItem.new(package.installed?.to_s))
      row += 1
    end
  end

  def updateAll
    for r in 0..(rowCount-1)
      name = item(r,0).text.intern
      item(r,1).setText(lookup(name).installed?.to_s)
    end
  end

end

class LogWindow < Qt::Widget
  def initialize
    super
    @log = Qt::TextEdit.new
    @log.setReadOnly(true)
    layout = Qt::VBoxLayout.new
    layout.addWidget(@log)
    setLayout(layout)
    adjustSize
  end

  def intercept_stdout
    $logging_callback = lambda do |t|
      puts t
      @log.append(t)
      $qApp.processEvents()
    end
  end

  def reset_stdout
    $logging_callback = lambda do |t|
      puts t
      $qApp.processEvents()
    end
  end
end

class PackageWidget < Qt::Widget
  signals :packageChanged
  attr_accessor :package

  def initialize
    super
    @description_label = Qt::Label.new("Description")
    @description = Qt::TextEdit.new
    @description.setReadOnly(true)

    @install_button = Qt::PushButton.new("Install")
    @remove_button = Qt::PushButton.new("Remove")
    @reinstall_button = Qt::PushButton.new("Reinstall")
    @other_button = Qt::PushButton.new("Other...")
    @install_button.connect(SIGNAL :clicked) do
      run_command 'install'
    end
    @remove_button.connect(SIGNAL :clicked) do
      run_command 'remove'
    end
    @reinstall_button.connect(SIGNAL :clicked) do
      run_command 'reinstall'
    end
    @other_button.connect(SIGNAL :clicked) do
      log "other"
    end
    @install_button.setEnabled(false)
    @remove_button.setEnabled(false)
    @reinstall_button.setEnabled(false)
    @other_button.setEnabled(false)

    layout = Qt::VBoxLayout.new()
    layout.addWidget(@description_label)
    layout.addWidget(@description)

    button_layout = Qt::GridLayout.new
    button_layout.addWidget(@install_button,0,0)
    button_layout.addWidget(@remove_button,0,1)
    button_layout.addWidget(@reinstall_button,1,0)
    button_layout.addWidget(@other_button,1,1)
    layout.addLayout(button_layout)

    setLayout(layout)
    adjustSize
  end

  def update_package(p)
    @package = p
    @description.setText(p.package_description.strip)
    @install_button.setEnabled(true)
    @remove_button.setEnabled(true)
    @reinstall_button.setEnabled(true)
#    @other_button.setEnabled(true)
  end

  def run_command(name)
    log_window = LogWindow.new
    log_window.intercept_stdout
    log_window.show
    begin 
      eval("@package.#{name}")
      log "finished"
      log_window.reset_stdout
      emit packageChanged()
      return true
    rescue Exception => e
      log "error #{e}"
      log_window.reset_stdout
      return false
    end
  end 
    
end

class MainWindow < Qt::Widget
  def initialize
    super    
    @package_table = PackageTable.new()
    @package_widget = PackageWidget.new()

    @package_table.connect(SIGNAL 'itemSelectionChanged()') do
      item = @package_table.selectedItems[0]
      package = lookup(item.text.intern)
      @package_widget.update_package(package)
    end
    @package_widget.connect(SIGNAL 'packageChanged()') do 
      @package_table.updateAll
    end

    layout = Qt::HBoxLayout.new()
    layout.addWidget(@package_table, 0, Qt::AlignLeft)
    layout.addWidget(@package_widget, 1)
    setLayout(layout)

    adjustSize
  end

end

GLOBAL_SETTINGS = {
  :package => {
    :directory => "/var/development/"
  },
  :tdsurface => {
    :password => "scimitar1"
  }
}

for path in Dir.glob("packages/*")
  require path if File.exists? path and path =~ /rb$/
end

app = Qt::Application.new(ARGV)

window = MainWindow.new()
window.show()

app.exec()
