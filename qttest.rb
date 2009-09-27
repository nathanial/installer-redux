require 'Qt4'
require 'package'

class PackageTable < Qt::TableWidget
  def initialize(parent = nil)
    super(parent)
    add_column("Package")
    add_column("Installed?")
    row = 0
    for name in $packages.keys
      insertRow(row)
      setItem(row, 0, Qt::TableWidgetItem.new(name.to_s))
      setItem(row, 1, Qt::TableWidgetItem.new(lookup(name).installed?.to_s))
      row += 1
    end
    setSizePolicy(Qt::SizePolicy.new(Qt::SizePolicy::Fixed, Qt::SizePolicy::Expanding))
    setSelectionMode(Qt::AbstractItemView::SingleSelection)
    setSelectionBehavior(Qt::AbstractItemView::SelectRows)
  end

  private
  def add_column(name)
    c = columnCount
    insertColumn(c)
    setHorizontalHeaderItem(c, Qt::TableWidgetItem.new(name))
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
end

class PackageWidget < Qt::Widget
  slots 'installPackage()', 'removePackage()'
  slots 'reinstallPackage()', 'other()'
  
  def initialize
    super
    @description_label = Qt::Label.new("Description")
    @description = Qt::TextEdit.new
    @description.setReadOnly(true)

    @install_button = Qt::PushButton.new("Install")
    @remove_button = Qt::PushButton.new("Remove")
    @reinstall_button = Qt::PushButton.new("Reinstall")
    @other_button = Qt::PushButton.new("Other...")
    connect(@install_button, SIGNAL('clicked()'), self, SLOT('installPackage()'))
    connect(@remove_button, SIGNAL('clicked()'), self, SLOT('removePackage()'))
    connect(@reinstall_button, SIGNAL('clicked()'), self, SLOT('reinstallPackage()'))
    connect(@other_button, SIGNAL('clicked()'), self, SLOT('other()'))

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
  end

  def installPackage
    log_window = LogWindow.new
    log_window.intercept_stdout
    log_window.show
    @package.install
  end

  def removePackage
    log_window = LogWindow.new
    log_window.intercept_stdout
    log_window.show
    @package.remove
  end
  
  def reinstallPackage
    log_window = LogWindow.new
    log_window.intercept_stdout
    log_window.show
    @package.remove
  end

  def other
    puts "other #@package"
  end

end

class MainWindow < Qt::Widget
  slots 'updatePackage()'
  def initialize
    super    
    @package_table = PackageTable.new()
    @package_widget = PackageWidget.new()

    connect(@package_table, SIGNAL('itemSelectionChanged()'), self, SLOT('updatePackage()'))

    layout = Qt::HBoxLayout.new()
    layout.addWidget(@package_table, 0, Qt::AlignLeft)
    layout.addWidget(@package_widget, 1)
    setLayout(layout)

    adjustSize
  end

  def updatePackage
    item = @package_table.selectedItems[0]
    if item.column == 0
      package = lookup(item.text.intern)
      @package_widget.update_package(package)
    end
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
