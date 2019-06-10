class ContumsController < ApplicationController
  respond_to :js, :html

  @@resultadoPositivoFicheiro = ""

  def self.getResultadoPositivoFicheiro
    @@resultadoPositivoFicheiro
  end
  def self.setResultadoPositivoFicheiro valor
    @@resultadoPositivoFicheiro  = valor
  end

  def index
    if @@telaAbertaConta == 1
      @@resultadoPositivoFicheiro = ""
    end
    @@telaAbertaConta = 0;

    if(params[:pesquisa] &&  params[:pesquisa] != '')
      @clientes = Cliente.pesquisa(params[:pesquisa])
    else
      @clientes = Cliente.listaClientes
    end

    @contasDevendo = [];
    @contasAtrasadas = [];
    @contasPagas = [];

  end

  def new
    if @@telaAbertaConta == 0
      @@resultadoPositivoFicheiro = ""
    end
    @@telaAbertaConta = 1
    if params[:pesquisaCliente] || params[:pesquisaFuncionario] || params[:pesquisaConta]
      carregarClientes params[:pesquisaCliente]
      carregarFuncionarios params[:pesquisaFuncionario]
      carregarContasData params[:pesquisaConta]
    else
      @clientes = Cliente.listaClientes
      @funcionarios = Funcionario.listaFuncionarios
      @contas = Contum.all
    end

    @contum = Contum.new
  end

  def show
    carregarContas(params[:id])
    render 'contums/index'
  end

  def edit
    @contum = Contum.find(params[:id])
    @contum.funcionario = Funcionario.find(@contum.funcionario).cpf
    @contum.cliente = Cliente.find(@contum.cliente).cpf
  end

  def update

    @conta = Contum.new(conta_params)

    if(@conta.status == "Paga")
      if(!@conta.dataPagamento || @conta.dataPagamento == '')
        time = Time.now
        @conta.dataPagamento = time;
      end
    end

    if !@conta.juros
      @conta.juros = 0
    end
    if !@conta.valor
      @conta.valor = 0
    end

    @cont = Contum.find(params[:id])
    @cont.update(valor: @conta.valor, juros: @conta.juros, status: @conta.status, dataPagamento: @conta.dataPagamento,
                 descricao: @conta.descricao, comprador: @conta.comprador, parentesco: @conta.parentesco)
    carregarContas @cont.cliente

    @@resultadoPositivoFicheiro = "Conta Atualizada"
    if @@telaAbertaConta == 0
      carregarContas(@cont.cliente)
      render 'contums/index'
    elsif @@telaAbertaConta == 1
      @contum = Contum.new
      carregarFuncionarios ''
      carregarClientes ''
      carregarContasData ''
      render 'contums/new'
    end
  end

  def create
    @contum = Contum.new(conta_params)

    if @contum.funcionario
      @contum.funcionario = Funcionario.listaFuncionarios.pesquisaCpf(@contum.funcionario)[0].id
    end

    if @contum.cliente
        @contum.cliente = Cliente.pesquisaCpf(@contum.cliente)[0].id
    end

    time = Time.now
    @contum.dataCompra = time;
    if(@contum.status == "Paga")
      @contum.dataPagamento = time;
    end

    if !@contum.juros
      @contum.juros = 0
    end
    if !@contum.valor
      @contum.valor = 0
    end

    if @contum.save
      @@resultadoPositivoFicheiro = "Conta salva"
      redirect_to new_contum_path
    else
      carregarClientes ''
      carregarFuncionarios ''
      render 'contums/new'
    end

  end

  def destroy

    @contum = Contum.find(params[:id])
    @contum.destroy
    @@resultadoPositivoFicheiro = "Conta Deletada"
    if @@telaAbertaConta == 0
      carregarContas(@contum.cliente)
      render 'contums/index'
    elsif @@telaAbertaConta == 1
      @contum = Contum.new
      carregarFuncionarios ''
      carregarClientes ''
      carregarContasData ''
      render 'contums/new'
    end
  end

  private
  # 0 = index, 1 = new
  @@telaAbertaConta = -1

  def conta_params
    params.require(:contum).permit(:cliente, :funcionario, :valor, :juros, :status, :descricao, :comprador, :parentesco)
  end

  def carregarContas id

    contas = Contum.listaContasCliente(id)
    @contasDevendo = contas.listaContasDevendo
    @contasAtrasadas = contas.listaContasAtrasadas
    @contasPagas = contas.listaContasPagas
    @clientes = Cliente.listaClientes
  end

  def carregarContasData data
    if data && data != ''
      data = data.split('/')[2] + '-' + data.split('/')[1] + '-' + data.split('/')[0];
      @contas = Contum.listaContasData data
    elsif !data
      @contas = nil;
    else
      @contas = Contum.all
    end
  end

  def carregarClientes pesquisa
    if pesquisa && pesquisa != ''
      @clientes = Cliente.pesquisa(pesquisa);
    elsif !pesquisa
      @clientes = nil
    else
      @clientes = Cliente.listaClientes
    end
  end

  def carregarFuncionarios pesquisa
    if pesquisa && pesquisa != ''
      @funcionarios = Funcionario.pesquisa(pesquisa)
    elsif !pesquisa
      @funcionarios = nil
    else
      @funcionarios = Funcionario.listaFuncionarios
    end
  end

end