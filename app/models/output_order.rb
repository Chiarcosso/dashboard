class OutputOrder < ApplicationRecord
  resourcify
  has_many :output_order_items, :dependent => :destroy
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

  def processed?
    self.processed ? 'Evaso' : 'Non evaso'
  end

  def print_module
    pdf = Prawn::Document.new
    pdf.font_size = 20
    # pdf.bounding_box() do
      pdf.text "RICEVUTA DI CONSEGNA DEI DPI AI LAVORATORI", align: :center
    # end
    pdf.move_down 20
    pdf.font_size = 12
    pdf.text "Il sottoscritto #{self.destination.complete_name}, dipendente della ditta #{self.destination.companies.first.name}", align: :center
    pdf.text "con mansione di #{self.destination.company_relations.first.name.downcase}, dichiara di ricevere il seguente materiale antinfortunistico:", align: :center
    pdf.move_down 20
    pdf.font_size = 10
    pdf.text "Reintegro periodico                                        Reintegro straordinario", align: :center

    pdf.font_size = 12
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

    pdf.move_down 20
    pdf.text "I sopracitati D.P.I. sono provvisti di marcatura \" C.E. \" e sono conformi alle vigenti normative", align: :center
    pdf.move_down 40
    pdf.text "Dichiara inoltre di impegnarsi ad utilizzare in maniera corretta i D.P.I. consegnatogli dalla ditta, come da informativa e formazine ricevute in sede di prima fornitura, ed a richiedere la sostituzione in caso di deterioramento o per un'eventuale intollerabilità.", align: :left
    pdf.move_down 100
    pdf.bounding_box([pdf.bounds.right-200,pdf.bounds.bottom+100], :width => 200, :height => 60) do
      pdf.text "Il lavoratore", align: :center
      pdf.move_down 20
      pdf.text "__________________", align: :center
    end
    pdf.font_size = 8
    pdf.bounding_box([pdf.bounds.left,pdf.bounds.bottom], :width => pdf.bounds.right, :height => 20) do
    	pdf.text 'Gruppo Chiarcosso', align: :left
    end
    pdf.bounding_box([pdf.bounds.left,pdf.bounds.bottom], :width => pdf.bounds.right, :height => 20) do
    	pdf.text 'Mod. 04 - Modulo reintegro D.P.I.', align: :center
    end
    pdf.bounding_box([pdf.bounds.left,pdf.bounds.bottom], :width => pdf.bounds.right, :height => 20) do
    	pdf.text 'Ed. 00 - Rev. 01 - 18/06/16', align: :right
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
