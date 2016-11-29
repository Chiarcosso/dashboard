class TransportDocumentsController < ApplicationController
  before_action :set_transport_document, only: [:show, :edit, :update, :destroy]

  # GET /transport_documents
  # GET /transport_documents.json
  def index
    @transport_documents = TransportDocument.all
  end

  # GET /transport_documents/1
  # GET /transport_documents/1.json
  def show
  end

  # GET /transport_documents/new
  def new
    @transport_document = TransportDocument.new
  end

  # GET /transport_documents/1/edit
  def edit
  end

  # POST /transport_documents
  # POST /transport_documents.json
  def create
    @transport_document = TransportDocument.new(transport_document_params)

    respond_to do |format|
      if @transport_document.save
        format.html { redirect_to @transport_document, notice: 'Transport document was successfully created.' }
        format.json { render :show, status: :created, location: @transport_document }
      else
        format.html { render :new }
        format.json { render json: @transport_document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transport_documents/1
  # PATCH/PUT /transport_documents/1.json
  def update
    respond_to do |format|
      if @transport_document.update(transport_document_params)
        format.html { redirect_to @transport_document, notice: 'Transport document was successfully updated.' }
        format.json { render :show, status: :ok, location: @transport_document }
      else
        format.html { render :edit }
        format.json { render json: @transport_document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transport_documents/1
  # DELETE /transport_documents/1.json
  def destroy
    @transport_document.destroy
    respond_to do |format|
      format.html { redirect_to transport_documents_url, notice: 'Transport document was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transport_document
      @transport_document = TransportDocument.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transport_document_params
      params.require(:transport_document).permit(:number, :date, :reason)
    end
end
