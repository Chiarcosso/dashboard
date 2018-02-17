class OutputOrder < ApplicationRecord
  resourcify

  before_destroy :recover_items

  has_many :output_order_items, :dependent => :destroy
  has_many :items, through: :output_order_items
  belongs_to :createdBy, class_name: User
  belongs_to :destination, polymorphic: true
  belongs_to :receiver, class_name: Person
  # belongs_to :worksheet, ->  { joins('inner join worksheets on destination_id = worksheets.id').where(:destination_type => 'Worksheet').where('destination_id == worksheet_.id') }

  # scope :unprocessed, -> { where(:processed => false)}

  # scope :unprocessed, -> { left_outer_joins(:output_order_items).where("output_order_items.id IS NOT NULL").where(:processed => false).distinct }
  scope :unprocessed, -> { where("id in (select output_order_id from output_order_items )").where(:processed => false).distinct }
  scope :processed, -> { where(:processed => true)}
  # scope :worksheet, -> { joins('inner join worksheets on destination_id = worksheets.id').where(:destination_type => 'Worksheet').where('destination_id == worksheet_.id') }
  scope :open_worksheets_filter, -> { joins('inner join worksheets on destination_id = worksheets.id').where(:destination_type => 'Worksheet').where('worksheets.closingDate is null') }


  def to_mobile_workshop?
    self.destination_type == 'Office' and Office.mobile_workshops.include? self.destination
  end

  def total
    total = 0
    self.output_order_items.each do |i|
      total += i.actual_price
    end
    total
  end

  def recover_items
    self.output_order_items.each do |ooi|
      ooi.recover_item
    end
  end

  def self.find_by_recipient(search)
    recipient = Worksheet.find_by_code(search)
    OutputOrder.where("destination_type = 'Worksheet' and destination_id = #{recipient.id}").last unless recipient.nil?
  end

  def self.findByRecipient(search,model = nil)
    if model.nil?
      recipients = Array.new
      recipients += Worksheet.filter(search).to_a
      recipients += Office.filter(search).to_a
      recipients += Person.filter(search).to_a
      recipients += Vehicle.filter(search).to_a
    else
      recipients = model.filter(search).to_a
    end
    receivers = Person.filter(search).to_a
    items = Item.assigned.filter(search).to_a
    # byebug
    hits = Array.new
    recipients.each do |r|
      unless r.nil?
        OutputOrder.where(destination_type: r.class.to_s).where(destination: r).each do |oo|
          hits << oo unless oo.nil?
        end
      end
    end
    receivers.each do |r|
      unless r.nil?
        OutputOrder.where(receiver: r).each do |oo|
          hits << oo unless oo.nil?
        end
      end
    end
    items.each do |r|
      unless r.nil?
        nogo = false
        oo = r.output_orders.order(:created_at).last
        hits.each do |h|
          if h == oo or oo.nil?
            nogo = true
          end
        end
        unless nogo
          hits << oo unless oo.nil?
        end
      end
    end
    hits
  end

  def compacted_items
    compact_list = Hash.new
    self.output_order_items.each do |i|
      if compact_list[i.item.article.complete_name].nil?
        compact_list[i.item.article.complete_name] = {:name => i.item.article.complete_name, :amount => i.quantity, :total_price => i.actual_price}
      else
        compact_list[i.item.article.complete_name][:amount] += i.quantity
        compact_list[i.item.article.complete_name][:total_price] += i.actual_price
      end
    end
    return compact_list
  end

  def compacted_items_serial
    compact_list = Hash.new
    self.items.each do |i|
      if compact_list[i.article.complete_name+i.serial.to_s].nil?
        compact_list[i.article.complete_name+i.serial.to_s] = {:name => i.article.complete_name, :amount => 1, :total_price => i.actual_price, :serial => i.serial, :id => i.id, :image => i.actualBarcode.to_s+'.png', :barcode => i.actualBarcode, :position => i.position_code.code}
      else
        compact_list[i.article.complete_name+i.serial.to_s][:amount] += 1
        compact_list[i.article.complete_name+i.serial.to_s][:total_price] += i.actual_price
      end
    end
    return compact_list
  end

  def processed?
    self.processed ? 'Evaso' : 'Non evaso'
  end

  def print_module
    pdf = Prawn::Document.new
    pdf.font_size = 20
    # pdf.bounding_box() do
    case self.destination_type
    when 'Person' then
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
      self.compacted_items.each do |i|
        table << [i[1][:amount] == i[1][:amount].to_i ? i[1][:amount].to_i : i[1][:amount],i[1][:name],Date.today.strftime("%d/%m/%Y")]
      end
      pdf.move_down 20
      pdf.table table,
        # :border_style => :grid,
        # :font_size => 11,
        :position => :center,
        :column_widths => { 0 => 30, 1 => 282, 2 => 90}
        # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
        # :row_colors => ["d2e3ed", "FFFFFF"]

      pdf.move_down 20
      pdf.text "I sopracitati D.P.I. sono provvisti di marcatura \" C.E. \" e sono conformi alle vigenti normative", align: :center
      pdf.move_down 40
      pdf.text "Dichiara inoltre di impegnarsi ad utilizzare in maniera corretta i D.P.I. consegnatogli dalla ditta, come da informativa e formazine ricevute in sede di prima fornitura, ed a richiedere la sostituzione in caso di deterioramento o per un'eventuale intollerabilità.", align: :left
      pdf.move_down 100
    when 'Vehicle' then
        pdf.text "RICEVUTA DI CONSEGNA ATTREZZATURA", align: :center
      # end
      pdf.move_down 40
      pdf.font_size = 14
      pdf.text "Il sottoscritto #{self.receiver.nil?? '______________________' : self.receiver.complete_name }, ritira la seguente attrezzatura per il mezzo targato #{self.destination.plate}:", align: :left
      # pdf.text "per il mezzo targato #{self.destination.plate}:", align: :left
      pdf.move_down 20
      pdf.font_size = 10
      # pdf.text "Reintegro periodico                                        Reintegro straordinario", align: :center

      pdf.font_size = 12
      table = [['N.','Oggetto','Data consegna']]
      self.compacted_items.each do |i|
        table << [i[1][:amount],i[1][:name],Date.today.strftime("%d/%m/%Y")]
      end
      pdf.move_down 20
      pdf.table table,
        # :border_style => :grid,
        # :font_size => 11,
        :position => :center,
        :column_widths => { 0 => 22, 1 => 290, 2 => 90}
        # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
        # :row_colors => ["d2e3ed", "FFFFFF"]

      pdf.move_down 160

    end
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
    	pdf.text '', align: :center
    end
    pdf.bounding_box([pdf.bounds.left,pdf.bounds.bottom], :width => pdf.bounds.right, :height => 20) do
    	pdf.text '', align: :right
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
    self.output_order_items.each do |i|
      table << ["#{i.item.article.complete_name} (#{i.quantity}/#{i.item.article.containedAmount})","#{i.item.serial}","#{i.item.position_code.code}","#{i.complete_price}"]
    end
    total = self.total.to_f
    if self.destination.class == Worksheet
      table << ["Ore di lavoro","","","#{self.destination.hours_complete_price}"]
      table << ["Materiale di consumo","","","#{self.destination.materials_complete_price}"]
      total += self.destination.hours_price
      total += self.destination.materials_price
    end

    table << ["Totale","","","#{"%.2f" % total} €".tr('.',',')]

    pdf.move_down 20
    pdf.table table,
      # :border_style => :grid,
      # :font_size => 11,
      :position => :center,
      :column_widths => { 0 => 170, 1 => 190, 2 => 73, 3 => 107},
      # :align => { 0 => :right, 1 => :left, 2 => :right, 3 => :left},
      :row_colors => ["d2e3ed", "FFFFFF"]

    pdf.bounding_box([pdf.bounds.right - 50,pdf.bounds.bottom], :width => 60, :height => 20) do
    	count = pdf.page_count
    	pdf.text "Page #{count}"
    end
    pdf
  end

end
