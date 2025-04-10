---
Date: 04/09/2025
Summary: "My experience using Twilio for Voice with Go: easy setup, quick calls, but limited AMD accuracy and no Terraform support."
Author: Kenton Vizdos
Tags: Go, Guides
---

## My Experience With Twilio For Voice

Overall, Twilio has had a great experience. It's easy to set up and use, and the documentation is comprehensive. However, there are a few critical aspects to consider when using Twilio for calls.

## The good

### It's incredibly easy to make a call.

Twilio uses `TwiML` to define the behavior of the call. TwiML is a simple XML-based language that allows you to define the behavior of the call, such as the audio to play, the actions to take, and the behavior of the call when it ends.

Creating an initial call is as simple as..

```go
package main

import (
	"fmt"
	"os"

	"github.com/twilio/twilio-go"
	api "github.com/twilio/twilio-go/rest/api/v2010"
)

func MakeCall(toNumber string, twimlEndpoint string) (*string, error) {
	client := twilio.NewRestClient()

	params := &api.CreateCallParams{}
	params.SetFrom(os.Getenv("TWILIO_NUMBER"))
	params.SetTo(toNumber)
	params.SetUrl(fmt.Sprintf("https://example.com/%s", twimlEndpoint))

	resp, err := client.Api.CreateCall(params)
	if err != nil {
		return nil, err
	}

	return resp.Sid, nil
}
```

### Making that call DO things is simple, too.

That endpoint as defined above, however, should return a TwiML response (...). Let's do it!

```go
type TwilioCallTWIML struct {
	Database database.DatabaseAccessor
}

func (t TwilioCallTWIML) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	resp := []twiml.Element{
		twiml.VoiceGather{
			Timeout:   "8",
			NumDigits: "1",
			Input:     "dtmf",
			Action:    "http://example.com/ivr-key",
			InnerElements: []twiml.Element{
				twiml.VoiceSay{
					Message: fmt.Sprintf("Wow, so simple! Press 1 to do something.", userInfo.FirstName),
				},
			},
		},
		twiml.VoiceSay{
			Message: "WHY DID YOU NOT PRESS 1!?!",
		},
	}

	twimlResult, err := twiml.Messages(resp)
	if err != nil {
		log.Errorf("Failed to generate TwiML: %s", err.Error())
		api_helpers.WriteResponse(w, api_helpers.APIResponseError{
			Reason:  "failed to generate TwiML",
			Details: err.Error(),
		}, http.StatusInternalServerError)
		return
	}
	w.Write([]byte(twimlResult))
}
```

This code will:
- Play a message to the user
- Gather input from the user
- IF no input, play "WHY DID YOU NOT PRESS 1!?!" to the user

It's honestly quite simple. The `/ivr-key` endpoint can then do any processing required, and serve up more TwiML to finish up the call (or do whatever else you need). You can get the `ivr key` pressed by using FormValue:

```go
digits := r.FormValue("Digits")
```

At any time, you can also use `VoiceRedirect` to redirect the call to another TwiML endpoint:

```go
twiml.VoiceRedirect{
	Url: "https://example.com/oh-my-a-redirect",
},
```

### Getting an Incoming Call

It's nearly identical to the outgoing call example, but you need to register the webhook within the Twilio console.

## The Not Great (TM)

### Answering Machine Detection (AMD)

"Near 100% Detection" MY ASS. I had about 30% accurate detection, AFTER tweaking the settings.

I just couldn't get it to work properly. It's a shame, because it seems like it'd be a powerful feature. I reallllly wanted to be able to play a certain message to a voicemail, but I had to eventually say `c'est la vie` and have a gap in voicemail, prior to falling back to "WHY DID YOU NOT PRESS 1!?!" (nicer in production, of course).

Like so many things, from a Consumer POV, I love the idea of robots having a hard time detecting answering machines. From a developer POV, I hate the idea of robots having a hard time detecting answering machines.

### No Terraform!

What is this, 2013? I need Terraform.. EVERYWHERE! Ever since switching to Terraform for literally everything else, I've saved so much time and effort. It's a game changer for infrastructure management. Not touching a UI to configure things is my dream.

## Conclusion

Twilio is a powerful tool for building voice applications. It's easy to use and has a wide range of features. However, it's not perfect. There are some limitations, such as the lack of (good) support for answering machine detection. Despite these limitations, Twilio is a great tool for building voice applications.
