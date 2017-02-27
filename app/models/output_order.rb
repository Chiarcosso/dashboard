class OutputOrder < ApplicationRecord
  resourcify
  has_many :output_order_items
  has_many :items, through: :output_order_items
  belongs_to :createdBy, class_name: User
  belongs_to :destination, polymorphic: true

  scope :unprocessed, -> { where(:processed => false)}
  scope :processed, -> { where(:processed => true)}

  def total
    total = 0
    self.items.each do |i|
      total += i.cost
    end
    total
  end

  def print_module
    pdf = Prawn::Document.new
    pdf.font_size = 20
    # pdf.bounding_box() do
      pdf.text "RICEVUTA DI CONSEGNA DEI DPI AI LAVORATORI", align: :center
    # end
    pdf.move_down 20
    pdf.font_size = 12
    pdf.text "Il sottoscritto #{self.destination.complete_name}, dipendente della ditta Chiarcosso Autotrasporti s.r.l.", align: :center
    pdf.text "con mansione di autista, dichiara di ricevere il seguente materiale antinfortunistico:", align: :center
    pdf.move_down 20
    pdf.text "Reintegro periodico                                        Reintegro straordinario", align: :center

    table = [['N.','DPI','Data consegna']]
    self.items.each do |i|
      table << [1,i.article.complete_name,Date.today.to_s]
    end
    pdf.move_down 20
    pdf.table table,
      # :border_style => :grid,
      # :font_size => 11,
      :position => :center,
      :column_widths => { 0 => 22, 1 => 290, 2 => 90}
      # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
      # :row_colors => ["d2e3ed", "FFFFFF"]

    pdf.bounding_box([pdf.bounds.right - 50,pdf.bounds.bottom], :width => 60, :height => 20) do
    	count = pdf.page_count
    	pdf.text "Page #{count}"
    end
    pdf
  end

  def print
    pdf = Prawn::Document.new
    pdf.text "Lista ordine di uscita nr. #{self.id}"
    case self.destination
    when Person
      pdf.text "rilasciato a: #{self.destination.complete_name}"
    when Vehicle
      pdf.text "destinato al mezzo: #{self.destination.complete_name}"
    when Worksheet
      pdf.text "per l'ODL nr. : #{self.destination.complete_name}"
    when Office
      pdf.text "destinato all'ufficio: #{self.destination.name}"
    end

    table = [['Articolo','Seriale/matricola','Posizione','Costo']]
    self.items.each do |i|
      table << ["#{i.article.complete_name}","#{i.serial}","#{i.position_code.code}","#{i.price} €"]
    end
    table << ["Totale","","","#{self.total} €"]

    pdf.move_down 20
    pdf.table table,
      # :border_style => :grid,
      # :font_size => 11,
      :position => :center,
      :column_widths => { 0 => 170, 1 => 190, 2 => 95, 3 => 85},
      # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
      :row_colors => ["d2e3ed", "FFFFFF"]

    pdf.bounding_box([pdf.bounds.right - 50,pdf.bounds.bottom], :width => 60, :height => 20) do
    	count = pdf.page_count
    	pdf.text "Page #{count}"
    end
    pdf
  end

end
