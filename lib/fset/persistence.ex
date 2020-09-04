defmodule Fset.Persistence do
  @moduledoc """
  The Persistence context.
  """

  import Ecto.Query, warn: false
  alias Fset.Repo

  alias Fset.Persistence.{File, OauthToken}

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
