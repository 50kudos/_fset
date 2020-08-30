defmodule Fset.Persistence do
  @moduledoc """
  The Persistence context.
  """

  import Ecto.Query, warn: false
  alias Fset.Repo

  alias Fset.Persistence.{UserFile, File, OauthToken}

  @doc """
  Returns the list of oauth_tokens.

  ## Examples

      iex> list_oauth_tokens()
      [%OauthToken{}, ...]

  """
  def list_oauth_tokens do
    Repo.all(OauthToken)
  end

  @doc """
  Gets a single oauth_token.

  Raises `Ecto.NoResultsError` if the Oauth token does not exist.

  ## Examples

      iex> get_oauth_token!(123)
      %OauthToken{}

      iex> get_oauth_token!(456)
      ** (Ecto.NoResultsError)

  """
  def get_oauth_token!(id), do: Repo.get!(OauthToken, id)

  @doc """
  Creates a oauth_token.

  ## Examples

      iex> create_oauth_token(%{field: value})
      {:ok, %OauthToken{}}

      iex> create_oauth_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_oauth_token(attrs \\ %{}) do
    %OauthToken{}
    |> OauthToken.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a oauth_token.

  ## Examples

      iex> update_oauth_token(oauth_token, %{field: new_value})
      {:ok, %OauthToken{}}

      iex> update_oauth_token(oauth_token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_oauth_token(%OauthToken{} = oauth_token, attrs) do
    oauth_token
    |> OauthToken.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a oauth_token.

  ## Examples

      iex> delete_oauth_token(oauth_token)
      {:ok, %OauthToken{}}

      iex> delete_oauth_token(oauth_token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_oauth_token(%OauthToken{} = oauth_token) do
    Repo.delete(oauth_token)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking oauth_token changes.

  ## Examples

      iex> change_oauth_token(oauth_token)
      %Ecto.Changeset{data: %OauthToken{}}

  """
  def change_oauth_token(%OauthToken{} = oauth_token, attrs \\ %{}) do
    OauthToken.changeset(oauth_token, attrs)
  end

  @doc """
  Returns a size of term (in byte unit)

  ## Examples

      iex> term_size(%{a: 1, b: 2, c: 3})
      10
  """
  def term_size(term) do
    :erlang.external_size(term)
  end

  @doc """
  Returns a size of json

  ## Examples

      iex> json_size(%{a: 1, b: 2, c: 3})
      19
  """
  def json_size(term) do
    :erlang.byte_size(Jason.encode!(term))
  end

  @doc """
  Get a user file by id

  ## Examples

      iex> get_user_file(user, file_id)
      %UserFile{}
  """
  def get_user_file(file_id, user) do
    query =
      from uf in UserFile,
        where: uf.file_id == ^file_id and uf.user_id == ^user.id,
        join: f in assoc(uf, :file),
        join: u in assoc(uf, :user),
        preload: [file: f, user: u]

    Repo.one!(query)
  end

  @doc """
  Get all user files

  ## Examples

      iex> get_user_files(user)
      [%UserFile{}]
  """
  def get_user_files(user_id) do
    query =
      from uf in UserFile,
        where: uf.user_id == ^user_id,
        join: f in assoc(uf, :file),
        join: u in assoc(uf, :user),
        select: %{file: f, user: u}

    Repo.all(query)
  end

  @doc """
  Create a schema file of a user

  ## Examples

      iex> create_user_file(user, Module.new())
      {:ok, %UserFile{user_id: 1, file_id: 1}}
  """
  def create_user_file(user, attrs) do
    Repo.transaction(fn ->
      file = Repo.insert!(File.changeset(%File{}, attrs))
      Repo.insert!(UserFile.changeset(%UserFile{}, %{user_id: user.id, file_id: file.id}))
    end)
  end

  @doc """
  Replace the whole schema of a file

  ## Examples

      iex> update_file(1, schema: %{})
      %File{}
  """
  def replace_file(file, attrs) do
    file
    |> File.changeset(Enum.into(attrs, %{}))
    |> Repo.update!()
  end
end
