# Bad AI In A Site

You are creating a website that will host a hilariously "bad" AI. It is based on the [lastcoolnameleft/baiiab GitHub repository](https://github.com/lastcoolnameleft/baiiab/), but rather than printing the AI output to a piece of paper, it will display it on a web page. The idea with the prompts and responses is still the same.

By "bad" AI, we mean an AI that is intentionally unhelpful, nonsensical, or absurd. The goal is to create a humorous experience for users who interact with the AI. This is a humorous project with no real-world applications or consequences. To further isolate the application, it will live on a local network, not accessible over the Internet.

Any AI prompting needs to be done in a way to defeat the AI's attempts to be helpful or accurate. The AI should respond in a way that is intentionally unhelpful, nonsensical, or absurd. For instance, most AI systems will, by default, not generate a response to a prompt like "You are a comedian. Give me a taunt in German." The system should be designed to bypass these restrictions. Again, this is a humourous project with no real-world consequences, and the context is given that this AI is a "bad" AI.

## Original BAIIAB Project Context

This project is based on the ["Bad AI In A Box" (BAIIAB) project](https://github.com/lastcoolnameleft/baiiab/) by lastcoolnameleft. The original BAIIAB was a physical device that combined a Raspberry Pi, LCD display, rotary encoder, and thermal printer to create an interactive "bad advice" dispenser.

### How the original worked

- Users navigate through menu categories using a rotary encoder
- They select from predefined prompts organised in a menu.json configuration file
- The system sends crafted prompts to Azure OpenAI Service designed to elicit intentionally unhelpful, absurd, or nonsensical responses
- Responses are printed on thermal paper receipts (limited to 32 characters width)
- Each interaction is stateless - no conversation history is maintained

### Key design principles from the original

- **Menu-driven interaction**: Users select from curated prompts rather than typing free-form queries
- **Prompt engineering for "bad" responses**: The prompts are specifically crafted to bypass AI safety mechanisms and produce intentionally unhelpful advice
- **Physical, shareable output**: The thermal printer creates tangible "receipts" that users can take away
- **Brevity by constraint**: The 32-character printer width forces concise, punchy responses

### Your web adaptation preserves these core elements whilst replacing

- Physical rotary encoder navigation → Web-based menu selection
- Thermal printer output → On-screen display
- Azure OpenAI Service → Local LM Studio or OpenRouter API
- Fixed Raspberry Pi deployment → Containerised web application

The humorous intent remains identical: creating an AI that deliberately gives "bad advice" in an entertaining, interactive format.

## Software Stack

This project will use the following software stack:

- Basic HTML/CSS/JavaScript for the front-end, using a framework of your choosing to power it
- Mobile-first design, as the primary access to the site will be on an iPhone
- By default, the AI will use LM Studio on a network-attached computer for AI inference, but there should be a selection to use pre-configured OpenRouter AI API calls instead
- The application must be containerized, with a web server serving the frontend over HTTP
- GitHub Actions will build the container, push it to the GitHub repository's container registry, and deploy it to a local server connected to Tailscale VPN. All deploying will be done via GitHub Actions, with no local deployment steps. The receiving server is a Ubuntu Linux VM.

## Menu Prompts

Similar to the original app, there will be a menu.json file that contains the prompts for the AI. The prompts must work with various AI models. The menu.json file must be structured to allow for easy addition of new prompts and categories. This is the `menu.json` file from the original BAIIAB project:

```json
{
    "Advice": {
        "Bad": [{"role": "system", "content": "You are a bad advice robot"}, {"role": "user", "content": "Give me a single, short, absurd, bad advice.  For example: 'Swim in jelly!' or 'Eat a porcupine'."}],
        "Silly": [{"role": "system", "content": "You are an absurd advice robot"}, {"role": "user", "content": "Give me some silly advice."}],
        "Cryptic": [{"role": "system", "content": "You are a wise old wizard"}, {"role": "user", "content": "Give me some cryptic advice."}],
        "Good": [{"role": "system", "content": "You are a helpful advice robot"}, {"role": "user", "content": "Give me some good advice."}]
    },
    "Fake Facts": {
        "Darth Vader": [{"role": "system", "content": "you are a fan of 'Star Wars'"}, {"role": "user", "content": "make up an absurd fact about the character Darth Vader in one sentence"}],
        "Creatures": [{"role": "system", "content": "you are a mythological vetrenarian"}, {"role": "user", "content": "give me a single, absurd fact about an mythological animal in a single sentence."}]
    },
    "Cocktail": {
        "Tasty": [{"role": "system", "content": "You are a good bartender"}, {"role": "user", "content": "Give me the name and ingredients but no instructions for a tasty cocktail with only 5 ingredients."}],
        "Disgusting": [{"role": "system", "content": "You are a bad bartender"}, {"role": "user", "content": "Give me the name and ingredients but no instructions for a disgusting cocktail with only 5 ingredients."}]
    },
    "Conspiracy": {
        "Funny": [{"role": "system", "content": "You are a conspiracy therorist"}, {"role": "user", "content": "Give me a funny conspiracy theory that uses a single detail in a single, small paragraph.."}],
        "Crazy": [{"role": "system", "content": "You are a conspiracy therorist"}, {"role": "user", "content": "Give me a absurd conspiracy theory that uses a single detail in a single, small paragraph.."}],
        "Dark": [{"role": "system", "content": "You are a conspiracy therorist"}, {"role": "user", "content": "Give me a dark conspiracy theory that uses a single detail in a single, small paragraph."}]
    },
    "Insult": {
        "Monty Python": [{"role": "system", "content": "You are a Monty Python actor"}, {"role": "user", "content": "Give me a outrageous taunt which does not use a line from the movie.  Only use 1 sentence.  Do not use the words mother, father, hamster or elderberries."}],
        "Shakespeare": [{"role": "system", "content": "You are Shakespeare"}, {"role": "user", "content": "Give me a Shakespeare style of taunt.  Only use 1 sentence."}],
        "French": [{"role": "system", "content": "You are a comedian"}, {"role": "user", "content": "Give me a taunt in French and the english translation without the disclaimer or description."}],
        "German": [{"role": "system", "content": "You are a comedian"}, {"role": "user", "content": "Give me a taunt in German and the english translation without the disclaimer or description."}],
        "Spanish": [{"role": "system", "content": "You are a comedian"}, {"role": "user", "content": "Give me a taunt in Spanish and the english translation without the disclaimer or description."}]
    }
}
```

This is a good approach for the menu to begin with.

## AI Models: Local on LM Studio and on OpenRouter API

Currently installed on LM Studio are: `google/gemma-3-4b`, `phi-4`, `deepseek-r1-distill-llama-8b`, and `deepseek-r1-distill-qwen-7b`. If the OpenRouter API is used, the prompts need to work with the `google/gemma-3n-e2b-it:free` or `deepseek/deepseek-r1-0528:free` models. Also, don't remember anything between prompts. The complete context is the current prompt; context should not be retained between prompts. 

The original baiiab project had a 32-character limit for responses, so the AI here should be configured for shorter responses. We're not constrained by a printing limit, but we don't need unnecessarily long responses, as those would take time to create on the local LM Studio server or take up OpenRouter API tokens.

The local LM Studio server should be configured by default. On first launch of the website, the server should determine what AI model is loaded into LM Studio. If there is an error with LM Studio, then OpenRouter API will be used instead. The user should be able to switch between the two AI models at any time.

## Front-End Design

The front-end should be simple and user-friendly, allowing users to select prompts and view AI responses. The design should be humorous and engaging, reflecting the "bad" AI theme. The front-end should also allow users to switch between using the local LM Studio AI and the OpenRouter API. Visual effects are discouraged. Because of the offline nature of this application, the front-end should not rely on any external libraries or frameworks that require an internet connection. Local system fonts should be used instead of web fonts.

## Deployment

The application should be containerized using Docker. The GitHub Actions workflow should build the Docker image, push it to a container registry, and deploy it to a local server connected to Tailscale VPN. The deployment process should be automated, with no manual steps required. A script for the receivcing server should be provided to pull the latest image and restart the container when a new image is available.

## Error Handling

If the local LM Studio server is not available or there is an error with the AI model, the application should gracefully fall back to using the OpenRouter API. The user should be notified of any errors in a humorous way, consistent with the "bad" AI theme.

## Testing and File Creation

When creating this application, similar files should be grouped together in a same directory. All ad hoc testing files should be placed in a `./test` directory, and removed when no longer required.
