package forms

import (
	"net/http/httptest"
	"net/url"
	"testing"
)

func TestForm_Valid(t *testing.T) {
	r := httptest.NewRequest("POST", "/whatever", nil)
	f := New(r.PostForm)
	if !f.Valid() {
		t.Error("got invalid from New(), when should have been valid")
	}
}

func TestForm_Required(t *testing.T) {
	r := httptest.NewRequest("POST", "/whatever", nil)
	f := New(r.PostForm)
	f.Required("a", "b", "c")
	if f.Valid() {
		t.Error("got valid from Required(), when should have been invalid")
	}
	postedData := url.Values{}
	postedData.Add("a", "a")
	postedData.Add("b", "b")
	postedData.Add("c", "c")
	r = httptest.NewRequest("POST", "/whatever", nil)
	r.PostForm = postedData
	f = New(r.PostForm)
	f.Required("a", "b", "c")
	if !f.Valid() {
		t.Error("got invalid from Required(), when should have been valid")
	}

}

func TestForm_Has(t *testing.T) {
	r := httptest.NewRequest("POST", "/whatever", nil)
	f := New(r.PostForm)
	if f.Has("a", r) {
		t.Error("got true from Has(), when should have been false")
	}
}

func TestForm_MinLengthInvalid(t *testing.T) {
	r := httptest.NewRequest("POST", "/whatever", nil)
	f := New(r.PostForm)
	f.Add("a", "12")
	if f.MinLength("a", 3, r) {
		t.Error("got true from MinLength(), when should have been false")
	}
}
