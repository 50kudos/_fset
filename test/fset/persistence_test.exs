defmodule Fset.PersistenceTest do
  use Fset.DataCase

  alias Fset.Persistence

  describe "oauth_tokens" do
    alias Fset.Persistence.OauthToken

    @valid_attrs %{
      avatar_url: "some avatar_url",
      provider: "some provider",
      refresh_token: "some refresh_token"
    }
    @update_attrs %{
      avatar_url: "some updated avatar_url",
      provider: "some updated provider",
      refresh_token: "some updated refresh_token"
    }
    @invalid_attrs %{avatar_url: nil, provider: nil, refresh_token: nil}

    def oauth_token_fixture(attrs \\ %{}) do
      {:ok, oauth_token} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Persistence.create_oauth_token()

      oauth_token
    end

    test "list_oauth_tokens/0 returns all oauth_tokens" do
      oauth_token = oauth_token_fixture()
      assert Persistence.list_oauth_tokens() == [oauth_token]
    end

    test "get_oauth_token!/1 returns the oauth_token with given id" do
      oauth_token = oauth_token_fixture()
      assert Persistence.get_oauth_token!(oauth_token.id) == oauth_token
    end

    test "create_oauth_token/1 with valid data creates a oauth_token" do
      assert {:ok, %OauthToken{} = oauth_token} = Persistence.create_oauth_token(@valid_attrs)
      assert oauth_token.avatar_url == "some avatar_url"
      assert oauth_token.provider == "some provider"
      assert oauth_token.refresh_token == "some refresh_token"
    end

    test "create_oauth_token/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Persistence.create_oauth_token(@invalid_attrs)
    end

    test "update_oauth_token/2 with valid data updates the oauth_token" do
      oauth_token = oauth_token_fixture()

      assert {:ok, %OauthToken{} = oauth_token} =
               Persistence.update_oauth_token(oauth_token, @update_attrs)

      assert oauth_token.avatar_url == "some updated avatar_url"
      assert oauth_token.provider == "some updated provider"
      assert oauth_token.refresh_token == "some updated refresh_token"
    end

    test "update_oauth_token/2 with invalid data returns error changeset" do
      oauth_token = oauth_token_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Persistence.update_oauth_token(oauth_token, @invalid_attrs)

      assert oauth_token == Persistence.get_oauth_token!(oauth_token.id)
    end

    test "delete_oauth_token/1 deletes the oauth_token" do
      oauth_token = oauth_token_fixture()
      assert {:ok, %OauthToken{}} = Persistence.delete_oauth_token(oauth_token)
      assert_raise Ecto.NoResultsError, fn -> Persistence.get_oauth_token!(oauth_token.id) end
    end

    test "change_oauth_token/1 returns a oauth_token changeset" do
      oauth_token = oauth_token_fixture()
      assert %Ecto.Changeset{} = Persistence.change_oauth_token(oauth_token)
    end
  end
end
