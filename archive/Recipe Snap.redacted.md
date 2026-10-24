Hey Grok, we're updating my iOS app, Recipe Snap. Recipe Snap is already available in the App Store, so any changes we make need to be extremely delicate to preserve the core functionality of the application. I will provide you with all of Xcode's .swift project files to provide context, and detail the specific changes we need to make to improve the UX/UI. Do not change any code EXCEPT what is specified. Do not provide me with unchanged .swift files, as this is redundant \- the files already exist in the Xcode project, only provide updated .swift files in your response.  
   
Specific Improvement: Currently, when you generate a recipe, the recipe generation text is listing the base ingredients: olive oil, salt, pepper, and water in all lower case \- this is incorrect. they should be formatted the same as other identified ingredients: with a capital letter to start. We need to be sure that when the base ingredients are mentioned in preparation, they are all lower case, unless they start the sentence, following the format of other identified ingredients. Also, they are being duplicated in the identified ingredients list \- identified ingredients should only be listed once, regardless if they appear in the photo or not.

Also, i need you to compile the app completely from the start in a new xcode project. 

We are removing the trial/paywall, it will be ads only now.

New app name: Instant Recipez  
   
APIService.swift:  
   
import Foundation  
class APIService {  
    private let apiKey \= "YOUR_XAI_API_KEY"  
    private let chatBaseURL \= "https\://api.x.ai/v1/chat/completions"  
    private let imageBaseURL \= "https\://api.x.ai/v1/images/generations"  
    private var lastUsedCulture: String?  
    private var lastRecipeTitle: String?  
    
    func identifyIngredients(base64Image: String, completion: @escaping (Result\<\[String\], Error\>) \-\> Void) {  
        guard \!apiKey.isEmpty else {  
            let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "API key is missing. Please try again."\])  
            print("Configuration Error: \\(error)")  
            completion(.failure(error))  
            return  
        }  
        
        guard \!base64Image.isEmpty else {  
            let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Invalid image data. Please try again."\])  
            print("Validation Error: Empty base64 image string")  
            completion(.failure(error))  
            return  
        }  
        
        if base64Image.count \> 10\_000\_000 {  
            let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Image size is too large. Please use a smaller image."\])  
            print("Validation Error: Base64 image string too large (\\(base64Image.count) characters)")  
            completion(.failure(error))  
            return  
        }  
        
        let prompt \= """  
        Identify the ingredients in this photo with 90% confidence that they are physically present. Accurately identify any visible text on bottles, cans, jars, and packaging. Only list ingredients that are clearly visible in the image or explicitly labeled on packaging. Return a JSON object with an 'ingredients' key containing an array of ingredient names.  
        """  
        let payload: \[String: Any\] \= \[  
            "model": "grok-2-vision-1212",  
            "messages": \[  
                \[  
                    "role": "user",  
                    "content": \[  
                        \["type": "text", "text": prompt\],  
                        \["type": "image\_url", "image\_url": \["url": "data:image/jpeg;base64,\\(base64Image)"\]\]  
                    \]  
                \]  
            \],  
            "response\_format": \["type": "json\_object"\],  
            "temperature": 0.5,  
            "stream": false  
        \]  
        
        makeAPIRequest(url: chatBaseURL, payload: payload, retryCount: 0\) { (result: Result\<Data, Error\>) in  
            switch result {  
            case .success(let data):  
                do {  
                    if let rawJSON \= String(data: data, encoding: .utf8) {  
                        print("Ingredient API Response: \\(rawJSON)")  
                    }  
                    let response \= try JSONDecoder().decode(IngredientApiResponse.self, from: data)  
                    guard let content \= response.choices.first?.message.content else {  
                        let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "No ingredients found in response. Please try again."\])  
                        print("Response Error: No content in API response")  
                        completion(.failure(error))  
                        return  
                    }  
                    
                    if let contentData \= content.data(using: .utf8),  
                       let contentJSON \= try? JSONSerialization.jsonObject(with: contentData) as? \[String: Any\],  
                       let ingredients \= contentJSON\["ingredients"\] as? \[String\] {  
                        let capitalizedIngredients \= ingredients.map { \$0.capitalized }  
                        completion(.success(capitalizedIngredients))  
                    } else {  
                        let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Failed to parse ingredients from response. Please try again."\])  
                        print("Parsing Error: Content is not a valid JSON object with 'ingredients' key")  
                        completion(.failure(error))  
                    }  
                } catch {  
                    if let errorResponse \= try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {  
                        let errorMessage \= errorResponse.error.message.isEmpty ? "Failed to identify ingredients. Please try again." : errorResponse.error.message  
                        let error \= NSError(domain: "", code: errorResponse.error.code ?? \-1, userInfo: \[NSLocalizedDescriptionKey: errorMessage\])  
                        print("API Error: \\(error) \- \\(errorMessage)")  
                        completion(.failure(error))  
                    } else {  
                        print("Decoding Error: \\(error)")  
                        let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Failed to parse ingredient response: \\(error.localizedDescription). Please try again."\])  
                        completion(.failure(error))  
                    }  
                }  
            case .failure(let error):  
                print("Ingredient API Error: \\(error)")  
                let error \= NSError(domain: "", code: (error as NSError).code, userInfo: \[NSLocalizedDescriptionKey: "Failed to identify ingredients: \\(error.localizedDescription). Please try again."\])  
                completion(.failure(error))  
            }  
        }  
    }  
    
    func generateRecipe(ingredients: \[String\], completion: @escaping (Result\<Recipe, Error\>) \-\> Void) {  
        guard \!apiKey.isEmpty else {  
            let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "API key is missing. Please try again."\])  
            print("Configuration Error: \\(error)")  
            completion(.failure(error))  
            return  
        }  
        
        let ingredientList \= ingredients.joined(separator: ", ")  
        let cultureExclusion \= lastUsedCulture \!= nil ? " (do not use \\(lastUsedCulture\!) cuisine)" : ""  
        let titleExclusion \= lastRecipeTitle \!= nil ? " (do not generate a recipe similar to \\(lastRecipeTitle\!))" : ""  
        let textPrompt \= """  
        Using EXACTLY the following explicitly identified ingredients from the photo: \\(ingredientList), plus ONLY the optional basic staples (olive oil, salt, pepper, water), generate a delicious recipe with a subtle cultural twist\\(cultureExclusion)\\(titleExclusion). The recipe MUST NOT include ANY ingredients not explicitly listed in the provided ingredients or the allowed staples (olive oil, salt, pepper, water), even if they are typical for the cultural style. The cultural twist should only influence the preparation style or flavor profile, not the ingredient list. The recipe must appeal to a broad audience while incorporating a hint of a culinary culture in its style, without being overly culture-specific. The recipe must not include any ingredients not explicitly listed in the provided ingredients or shown in the photo, except the staples. Exclude any microwave cooking methods. The recipe should include:  
        \- A title  
        \- A short, exciting description (1-2 sentences) to entice the user  
        \- A list of ingredients (as a single string, with staples listed as olive oil, salt, pepper, water)  
        \- Detailed preparation instructions (as an array of individual steps)  
        Return the response as a JSON object with 'title', 'description', 'ingredients', 'instructions', and 'culture' fields, where 'culture' identifies the culinary culture (e.g., 'Italian-inspired', 'Mexican-inspired', 'Japanese-inspired').  
        """  
        let textPayload: \[String: Any\] \= \[  
            "model": "grok-2-vision-1212",  
            "messages": \[  
                \[  
                    "role": "user",  
                    "content": textPrompt  
                \]  
            \],  
            "response\_format": \["type": "json\_object"\],  
            "temperature": 0.7,  
            "stream": false  
        \]  
        
        makeAPIRequest(url: chatBaseURL, payload: textPayload, retryCount: 0\) { (result: Result\<Data, Error\>) in  
            switch result {  
            case .success(let data):  
                do {  
                    if let rawJSON \= String(data: data, encoding: .utf8) {  
                        print("Recipe Text API Response: \\(rawJSON)")  
                    }  
                    let textResponse \= try JSONDecoder().decode(RecipeTextResponse.self, from: data)  
                    guard let contentString \= textResponse.choices.first?.message.content,  
                          let contentData \= contentString.data(using: .utf8) else {  
                        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: \[\], debugDescription: "Invalid content format"))  
                    }  
                    let partialRecipe \= try JSONDecoder().decode(PartialRecipe.self, from: contentData)  
                    
                    let allowedIngredients \= Set(ingredients.map { \$0.lowercased() } \+ \["olive oil", "salt", "pepper", "water"\])  
                    let recipeIngredients \= partialRecipe.ingredients.lowercased()  
                        .components(separatedBy: ", ")  
                        .flatMap { \$0.split(separator: " and ").map { String(\$0) } }  
                        .map { \$0.trimmingCharacters(in: .whitespaces) }  
                    if recipeIngredients.contains(where: { \!allowedIngredients.contains(\$0) }) {  
                        print("Invalid ingredients detected: \\(recipeIngredients.filter { \!allowedIngredients.contains(\$0) })")  
                        let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Generated recipe contains invalid ingredients. Please try again."\])  
                        completion(.failure(error))  
                        return  
                    }  
                    
                    if let culture \= partialRecipe.culture {  
                        self.lastUsedCulture \= culture  
                    }  
                    self.lastRecipeTitle \= partialRecipe.title  
                    
                    let imagePrompt \= """  
                    A realistic, appetizing dish of \\(partialRecipe.title), beautifully plated with natural lighting, authentic textures, and a delightful presentation that looks as if it were photographed in a real kitchen, avoiding any artificial or computer-generated effects. The dish must ONLY include the following ingredients: \\(partialRecipe.ingredients). Do not include any ingredients not explicitly listed.  
                    """  
                    let imagePayload: \[String: Any\] \= \[  
                        "model": "grok-2-image-1212",  
                        "prompt": imagePrompt,  
                        "n": 1,  
                        "response\_format": "b64\_json"  
                    \]  
                    
                    self.makeAPIRequest(url: self.imageBaseURL, payload: imagePayload, retryCount: 0\) { (result: Result\<Data, Error\>) in  
                        switch result {  
                        case .success(let imageData):  
                            do {  
                                if let rawJSON \= String(data: imageData, encoding: .utf8) {  
                                    print("Recipe Image API Response: \\(rawJSON)")  
                                }  
                                let imageResponse \= try JSONDecoder().decode(ImageResponse.self, from: imageData)  
                                let recipe \= Recipe(  
                                    id: UUID(),  
                                    title: partialRecipe.title,  
                                    description: partialRecipe.description,  
                                    ingredients: partialRecipe.ingredients,  
                                    instructions: partialRecipe.instructions,  
                                    imageBase64: imageResponse.data.first?.b64Json ?? "",  
                                    createdAt: Date()  
                                )  
                                completion(.success(recipe))  
                            } catch {  
                                print("Image Decoding Error: \\(error)")  
                                let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Failed to parse image response. Please try again."\])  
                                completion(.failure(error))  
                            }  
                        case .failure(let error):  
                            print("Image API Error: \\(error)")  
                            let updatedError \= NSError(domain: "", code: (error as NSError).code, userInfo: \[NSLocalizedDescriptionKey: "Failed to generate recipe image: \\(error.localizedDescription). Please try again."\])  
                            completion(.failure(updatedError))  
                        }  
                    }  
                } catch {  
                    if let errorResponse \= try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {  
                        let errorMessage \= errorResponse.error.message.isEmpty ? "Failed to generate recipe. Please try again." : errorResponse.error.message  
                        let error \= NSError(domain: "", code: errorResponse.error.code ?? \-1, userInfo: \[NSLocalizedDescriptionKey: errorMessage\])  
                        print("Text API Error: \\(error) \- \\(errorMessage)")  
                        completion(.failure(error))  
                    } else {  
                        print("Text Decoding Error: \\(error)")  
                        let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Failed to parse recipe response. Please try again."\])  
                        completion(.failure(error))  
                    }  
                }  
            case .failure(let error):  
                print("Recipe Text API Error: \\(error)")  
                let updatedError \= NSError(domain: "", code: (error as NSError).code, userInfo: \[NSLocalizedDescriptionKey: "Failed to generate recipe: \\(error.localizedDescription). Please try again."\])  
                completion(.failure(updatedError))  
            }  
        }  
    }  
    
    private func makeAPIRequest(url: String, payload: \[String: Any\], retryCount: Int, completion: @escaping (Result\<Data, Error\>) \-\> Void) {  
        guard let urlObj \= URL(string: url) else {  
            let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Invalid API URL. Please try again."\])  
            print("Invalid URL: \\(error)")  
            completion(.failure(error))  
            return  
        }  
        
        var request \= URLRequest(url: urlObj)  
        request.httpMethod \= "POST"  
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")  
        request.setValue("Bearer \\(apiKey)", forHTTPHeaderField: "Authorization")  
        
        do {  
            let jsonData \= try JSONSerialization.data(withJSONObject: payload)  
            request.httpBody \= jsonData  
            if let jsonString \= String(data: jsonData, encoding: .utf8) {  
                print("Request Payload: \\(jsonString)")  
            }  
        } catch {  
            print("Payload Error: \\(error)")  
            let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Failed to encode API request. Please try again."\])  
            completion(.failure(error))  
            return  
        }  
        
        URLSession.shared.dataTask(with: request) { data, response, error in  
            if let error \= error {  
                print("Network Error: \\(error)")  
                let updatedError \= NSError(domain: "", code: (error as NSError).code, userInfo: \[NSLocalizedDescriptionKey: "Network error: \\(error.localizedDescription). Please try again."\])  
                completion(.failure(updatedError))  
                return  
            }  
            
            guard let httpResponse \= response as? HTTPURLResponse else {  
                let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "Invalid API response. Please try again."\])  
                print("Invalid Response: \\(error)")  
                completion(.failure(error))  
                return  
            }  
            
            print("HTTP Status: \\(httpResponse.statusCode)")  
            if let headers \= httpResponse.allHeaderFields as? \[String: String\] {  
                print("Headers: \\(headers)")  
            }  
            
            if httpResponse.statusCode \== 401 {  
                let error \= NSError(domain: "", code: 401, userInfo: \[NSLocalizedDescriptionKey: "Authentication failed. Please try again."\])  
                print("Authentication Error: \\(error)")  
                completion(.failure(error))  
                return  
            }  
            
            if \[502, 429, 400\].contains(httpResponse.statusCode) && retryCount \< 3 {  
                let retryDelay \= httpResponse.statusCode \== 429 ? 5.0 : 2.0  
                print("Received \\(httpResponse.statusCode) error, retrying (\\(retryCount \+ 1)/3) after \\(retryDelay) seconds...")  
                DispatchQueue.global().asyncAfter(deadline: .now() \+ retryDelay) {  
                    self.makeAPIRequest(url: url, payload: payload, retryCount: retryCount \+ 1, completion: completion)  
                }  
                return  
            }  
            
            guard (200...299).contains(httpResponse.statusCode) else {  
                let error \= NSError(domain: "", code: httpResponse.statusCode, userInfo: \[NSLocalizedDescriptionKey: "API error (\\(httpResponse.statusCode)): Please try again."\])  
                if let data \= data, let errorBody \= String(data: data, encoding: .utf8) {  
                    print("Error Response: \\(errorBody)")  
                }  
                completion(.failure(error))  
                return  
            }  
            
            guard let data \= data else {  
                let error \= NSError(domain: "", code: \-1, userInfo: \[NSLocalizedDescriptionKey: "No data received from API. Please try again."\])  
                print("No Data: \\(error)")  
                completion(.failure(error))  
                return  
            }  
            
            completion(.success(data))  
        }.resume()  
    }  
}  
private struct IngredientApiResponse: Decodable {  
    let choices: \[Choice\]  
    
    struct Choice: Decodable {  
        let message: Message  
        
        struct Message: Decodable {  
            let content: String  
        }  
    }  
}  
private struct RecipeTextResponse: Decodable {  
    let choices: \[Choice\]  
    
    struct Choice: Decodable {  
        let message: Message  
        
        struct Message: Decodable {  
            let content: String  
        }  
    }  
}  
private struct PartialRecipe: Decodable {  
    let title: String  
    let description: String  
    let ingredients: String  
    let instructions: \[String\]  
    let culture: String?  
    
    enum CodingKeys: String, CodingKey {  
        case title, description, ingredients, instructions, culture  
    }  
}  
private struct ImageResponse: Decodable {  
    let data: \[ImageData\]  
    
    struct ImageData: Decodable {  
        let b64Json: String  
        
        enum CodingKeys: String, CodingKey {  
            case b64Json \= "b64\_json"  
        }  
    }  
}  
private struct ApiErrorResponse: Decodable {  
    let error: ErrorDetails  
    
    struct ErrorDetails: Decodable {  
        let message: String  
        let code: Int?  
    }  
}  
   
BookmarkManager.swift:  
   
import Foundation  
class BookmarkManager: ObservableObject {  
    @Published var bookmarkedRecipes: \[Recipe\] \= \[\]  
    private let bookmarkKey \= "BookmarkedRecipes"  
     
    init() {  
        loadBookmarks()  
    }  
     
    func addRecipe(\_ recipe: Recipe) {  
        if \!bookmarkedRecipes.contains(where: { \$0.id \== recipe.id }) {  
            let timestampedRecipe \= Recipe(  
                id: recipe.id,  
                title: recipe.title,  
                description: recipe.description,  
                ingredients: recipe.ingredients,  
                instructions: recipe.instructions,  
                imageBase64: recipe.imageBase64,  
                createdAt: Date()  
            )  
            bookmarkedRecipes.insert(timestampedRecipe, at: 0\)  
            saveBookmarks()  
        }  
    }  
     
    func removeRecipe(\_ recipe: Recipe) {  
        bookmarkedRecipes.removeAll { \$0.id \== recipe.id }  
        saveBookmarks()  
    }  
     
    func isBookmarked(\_ recipe: Recipe) \-\> Bool {  
        bookmarkedRecipes.contains { \$0.id \== recipe.id }  
    }  
     
    private func saveBookmarks() {  
        if let data \= try? JSONEncoder().encode(bookmarkedRecipes) {  
            UserDefaults.standard.set(data, forKey: bookmarkKey)  
        }  
    }  
     
    private func loadBookmarks() {  
        if let data \= UserDefaults.standard.data(forKey: bookmarkKey),  
           let recipes \= try? JSONDecoder().decode(\[Recipe\].self, from: data) {  
            bookmarkedRecipes \= recipes.sorted { (recipe1, recipe2) \-\> Bool in  
                let date1 \= recipe1.createdAt ?? .distantPast  
                let date2 \= recipe2.createdAt ?? .distantPast  
                return date1 \> date2  
            }  
        }  
    }  
}  
   
   
CameraPicker.swift:  
   
import SwiftUI  
import AVFoundation  
import UIKit  
struct CameraPicker: UIViewControllerRepresentable {  
    var onImagePicked: (Data?) \-\> Void  
     
    func makeUIViewController(context: Context) \-\> CameraViewController {  
        let controller \= CameraViewController()  
        controller.onImagePicked \= onImagePicked  
        return controller  
    }  
     
    func updateUIViewController(\_ uiViewController: CameraViewController, context: Context) {  
    }  
}  
class CameraViewController: UIViewController {  
    var onImagePicked: ((Data?) \-\> Void)?  
     
    private var captureSession: AVCaptureSession?  
    private var previewLayer: AVCaptureVideoPreviewLayer?  
    private var photoOutput: AVCapturePhotoOutput?  
    private var flashMode: AVCaptureDevice.FlashMode \= .off  
     
    private var previewView: UIView\!  
    private var shutterButton: UIButton\!  
    private var flashButton: UIButton\!  
    private var cancelButton: UIButton\!  
    private var shutterBorderGradient: CAGradientLayer?  
     
    override func viewDidLoad() {  
        super.viewDidLoad()  
        view.backgroundColor \= .black  
         
        view.clipsToBounds \= false  
         
        previewView \= UIView(frame: view.bounds)  
        previewView.backgroundColor \= .clear  
        previewView.clipsToBounds \= false  
        previewView.autoresizingMask \= \[.flexibleWidth, .flexibleHeight\]  
        view.addSubview(previewView)  
         
        setupCamera()  
        setupOverlay()  
    }  
     
    override func viewWillAppear(\_ animated: Bool) {  
        super.viewWillAppear(animated)  
         
        DispatchQueue.main.async { \[weak self\] in  
            self?.startShutterButtonAnimation()  
        }  
         
        setNeedsStatusBarAppearanceUpdate()  
    }  
     
    override func viewWillDisappear(\_ animated: Bool) {  
        super.viewWillDisappear(animated)  
         
        DispatchQueue.global(qos: .userInitiated).async { \[weak self\] in  
            print("Stopping capture session on thread: \\(Thread.current)")  
            self?.captureSession?.stopRunning()  
        }  
         
        shutterBorderGradient?.removeAllAnimations()  
    }  
     
    override func viewDidLayoutSubviews() {  
        super.viewDidLayoutSubviews()  
        previewView.frame \= view.bounds  
        previewLayer?.frame \= previewView.bounds  
        updateOverlayFrames()  
         
        if shutterButton.bounds \!= .zero {  
            shutterBorderGradient?.frame \= shutterButton.bounds  
        }  
         
    }  
     
    override var prefersStatusBarHidden: Bool {  
        return false  
    }  
     
    override var preferredStatusBarStyle: UIStatusBarStyle {  
        return .lightContent  
    }  
     
    private func setupCamera() {  
        AVCaptureDevice.requestAccess(for: .video) { \[weak self\] granted in  
            guard granted else {  
                print("Camera access denied")  
                DispatchQueue.main.async {  
                    self?.onImagePicked?(nil)  
                    self?.dismiss(animated: true, completion: nil)  
                }  
                return  
            }  
             
            DispatchQueue.main.async {  
                print("Camera access granted, initializing camera")  
                self?.initializeCamera()  
            }  
        }  
    }  
     
    private func initializeCamera() {  
        let session \= AVCaptureSession()  
        session.sessionPreset \= .photo  
        captureSession \= session  
         
        guard let camera \= AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),  
              let input \= try? AVCaptureDeviceInput(device: camera) else {  
            print("Error: Unable to initialize camera")  
            onImagePicked?(nil)  
            dismiss(animated: true, completion: nil)  
            return  
        }  
         
        if session.canAddInput(input) {  
            print("Adding camera input")  
            session.addInput(input)  
        } else {  
            print("Error: Unable to add camera input")  
            onImagePicked?(nil)  
            dismiss(animated: true, completion: nil)  
            return  
        }  
         
        let output \= AVCapturePhotoOutput()  
        if session.canAddOutput(output) {  
            print("Adding photo output")  
            session.addOutput(output)  
            photoOutput \= output  
        } else {  
            print("Error: Unable to add photo output")  
            onImagePicked?(nil)  
            dismiss(animated: true, completion: nil)  
            return  
        }  
         
        let layer \= AVCaptureVideoPreviewLayer(session: session)  
        layer.videoGravity \= .resizeAspectFill  
        layer.frame \= previewView.bounds  
        previewView.layer.addSublayer(layer)  
        previewLayer \= layer  
        print("Preview layer added with frame: \\(layer.frame)")  
         
        DispatchQueue.global(qos: .userInitiated).async { \[weak session\] in  
            print("Starting capture session on thread: \\(Thread.current)")  
            session?.startRunning()  
            DispatchQueue.main.async { \[weak self\] in  
                guard let self \= self, let session \= session else { return }  
                print("Session running: \\(session.isRunning)")  
                self.previewLayer?.connection?.isEnabled \= true  
                self.previewLayer?.frame \= self.previewView.bounds  
                print("Preview layer updated after session start: \\(self.previewLayer?.frame ?? .zero)")  
            }  
        }  
    }  
     
    private func setupOverlay() {  
        shutterButton \= UIButton(type: .custom)  
        shutterButton.backgroundColor \= .white  
        shutterButton.layer.cornerRadius \= 40  
        shutterButton.addTarget(self, action: \#selector(takePhoto), for: .touchUpInside)  
        view.addSubview(shutterButton)  
         
        let gradient \= CAGradientLayer()  
        gradient.frame \= shutterButton.bounds  
        gradient.type \= .conic  
        gradient.colors \= \[  
            UIColor.red.cgColor,  
            UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0).cgColor,  
            UIColor.orange.cgColor,  
            UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1.0).cgColor,  
            UIColor.yellow.cgColor,  
            UIColor(red: 0.5, green: 1.0, blue: 0.0, alpha: 1.0).cgColor,  
            UIColor.green.cgColor,  
            UIColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0).cgColor,  
            UIColor.blue.cgColor,  
            UIColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 1.0).cgColor,  
            UIColor.purple.cgColor,  
            UIColor(red: 0.75, green: 0.0, blue: 0.5, alpha: 1.0).cgColor,  
            UIColor.red.cgColor  
        \]  
        gradient.startPoint \= CGPoint(x: 0.5, y: 0.5)  
        gradient.endPoint \= CGPoint(x: 1.0, y: 0.5)  
         
        let shape \= CAShapeLayer()  
        let path \= UIBezierPath(roundedRect: shutterButton.bounds.insetBy(dx: 2.5, dy: 2.5), cornerRadius: 37.5)  
        shape.path \= path.cgPath  
        shape.lineWidth \= 5  
        shape.strokeColor \= UIColor.black.cgColor  
        shape.fillColor \= nil  
         
        gradient.mask \= shape  
        shutterButton.layer.addSublayer(gradient)  
        shutterBorderGradient \= gradient  
         
        flashButton \= UIButton(type: .custom)  
        flashButton.setImage(UIImage(systemName: "bolt.slash.fill"), for: .normal)  
        flashButton.tintColor \= .white  
        flashButton.addTarget(self, action: \#selector(toggleFlash), for: .touchUpInside)  
        view.addSubview(flashButton)  
         
        cancelButton \= UIButton(type: .custom)  
        cancelButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)  
        cancelButton.tintColor \= .white  
        cancelButton.addTarget(self, action: \#selector(cancel), for: .touchUpInside)  
        view.addSubview(cancelButton)  
         
        updateOverlayFrames()  
    }  
     
    private func updateOverlayFrames() {  
        let safeArea \= view.safeAreaInsets  
        let shutterButtonSize: CGFloat \= 80  
         
        shutterButton.frame \= CGRect(  
            x: (view.bounds.width \- shutterButtonSize) / 2,  
            y: view.bounds.height \- shutterButtonSize \- safeArea.bottom \- 20,  
            width: shutterButtonSize,  
            height: shutterButtonSize  
        )  
         
        flashButton.frame \= CGRect(  
            x: 20,  
            y: safeArea.top \+ 30,  
            width: 40,  
            height: 40  
        )  
         
        cancelButton.frame \= CGRect(  
            x: view.bounds.width \- 60,  
            y: safeArea.top \+ 30,  
            width: 40,  
            height: 40  
        )  
         
        if shutterButton.bounds \!= .zero {  
            shutterBorderGradient?.frame \= shutterButton.bounds  
            if let shape \= shutterBorderGradient?.mask as? CAShapeLayer {  
                shape.path \= UIBezierPath(roundedRect: shutterButton.bounds.insetBy(dx: 2.5, dy: 2.5), cornerRadius: 37.5).cgPath  
            }  
        }  
    }  
     
    private func startShutterButtonAnimation() {  
        guard let gradient \= shutterBorderGradient else { return }  
         
        if gradient.frame \== .zero {  
            print("Gradient frame is zero, skipping animation start")  
            return  
        }  
         
        let rotationAnimation \= CABasicAnimation(keyPath: "transform.rotation.z")  
        rotationAnimation.fromValue \= 0  
        rotationAnimation.toValue \= 2 \* Double.pi  
        rotationAnimation.duration \= 5.0  
        rotationAnimation.repeatCount \= .infinity  
        rotationAnimation.timingFunction \= CAMediaTimingFunction(name: .linear)  
        gradient.add(rotationAnimation, forKey: "rotationAnimation")  
         
        let opacityAnimation \= CABasicAnimation(keyPath: "opacity")  
        opacityAnimation.fromValue \= 0.7  
        opacityAnimation.toValue \= 1.0  
        opacityAnimation.duration \= 2.0  
        opacityAnimation.repeatCount \= .infinity  
        opacityAnimation.autoreverses \= true  
        opacityAnimation.timingFunction \= CAMediaTimingFunction(name: .easeInEaseOut)  
        gradient.add(opacityAnimation, forKey: "opacityAnimation")  
    }  
     
    @objc private func takePhoto() {  
        print("Shutter button tapped, frame: \\(shutterButton.frame)")  
        guard let photoOutput \= photoOutput else {  
            print("Error: Photo output not available")  
            return  
        }  
         
        let settings \= AVCapturePhotoSettings()  
        settings.flashMode \= flashMode  
        photoOutput.capturePhoto(with: settings, delegate: self)  
    }  
     
    @objc private func toggleFlash() {  
        print("Flash button tapped, frame: \\(flashButton.frame)")  
        flashMode \= (flashMode \== .off) ? .on : .off  
        let imageName \= flashMode \== .on ? "bolt.fill" : "bolt.slash.fill"  
        flashButton.setImage(UIImage(systemName: imageName), for: .normal)  
    }  
     
    @objc private func cancel() {  
        print("Cancel button tapped, frame: \\(cancelButton.frame)")  
        onImagePicked?(nil)  
        dismiss(animated: true, completion: nil)  
    }  
}  
extension CameraViewController: AVCapturePhotoCaptureDelegate {  
    func photoOutput(\_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {  
        if let error \= error {  
            print("Error capturing photo: \\(error.localizedDescription)")  
            onImagePicked?(nil)  
            dismiss(animated: true, completion: nil)  
            return  
        }  
         
        guard let imageData \= photo.fileDataRepresentation(),  
              let image \= UIImage(data: imageData),  
              let compressedData \= image.jpegData(compressionQuality: 0.8) else {  
            print("Error processing photo data")  
            onImagePicked?(nil)  
            dismiss(animated: true, completion: nil)  
            return  
        }  
         
        onImagePicked?(compressedData)  
        dismiss(animated: true, completion: nil)  
    }  
}  
   
   
ContentView.swift:  
   
import SwiftUI  
import UIKit  
struct ContentView: View {  
    @StateObject private var viewModel \= RecipeViewModel()  
    @StateObject private var trialManager \= TrialManager()  
    @StateObject private var purchaseManager \= PurchaseManager()  
    @StateObject private var adViewModel \= NativeAdViewModel()  
    @State private var showCamera \= false  
    @State private var showRecipe \= false  
    @State private var showCollection \= false  
    @State private var showNativeAd \= false  
    @State private var showSubscriptionSplash \= false  
    @State private var hasShownSubscriptionSplash \= false  
    @State private var animateLogo \= false  
    @State private var animateBookmark \= false  
    @State private var animateTitle \= false  
    @State private var animateDescription \= false  
    @State private var animateButton \= false  
    @State private var animateSubscriptionText \= false  
    
    var body: some View {  
        GeometryReader { geometry in  
            ZStack {  
                Color.white.edgesIgnoringSafeArea(.all)  
                
                if showRecipe, let recipe \= viewModel.recipe {  
                    RecipeCardView(  
                        recipe: recipe,  
                        isFromBookmarks: false,  
                        onBack: {  
                            withAnimation {  
                                triggerHaptic()  
                                showRecipe \= false  
                                viewModel.recipe \= nil  
                                if \!purchaseManager.isSubscribed && trialManager.remainingUses \== 0 && \!hasShownSubscriptionSplash {  
                                    print("Showing subscription splash from RecipeCardView onBack")  
                                    showSubscriptionSplash \= true  
                                    hasShownSubscriptionSplash \= true  
                                }  
                            }  
                        },  
                        onNewRecipe: {  
                            if let lastImageData \= viewModel.lastImageData {  
                                withAnimation {  
                                    adViewModel.startProgressAnimation()  
                                    showNativeAd \= true  
                                    viewModel.processPhoto(lastImageData) { result in  
                                        DispatchQueue.main.async {  
                                            showNativeAd \= false  
                                            if \!result {  
                                                showRecipe \= false  
                                                viewModel.recipe \= nil  
                                                if \!purchaseManager.isSubscribed && trialManager.remainingUses \== 0 && \!hasShownSubscriptionSplash {  
                                                    print("Showing subscription splash from RecipeCardView onNewRecipe")  
                                                    showSubscriptionSplash \= true  
                                                    hasShownSubscriptionSplash \= true  
                                                }  
                                            }  
                                        }  
                                    }  
                                }  
                            }  
                        },  
                        isSubscribed: purchaseManager.isSubscribed  
                    )  
                    .environmentObject(viewModel)  
                    .transition(.opacity)  
                } else if showCollection {  
                    RecipeCollectionView(onBack: {  
                        withAnimation(.easeOut(duration: 0.69)) {  
                            triggerHaptic()  
                            showCollection \= false  
                            if \!purchaseManager.isSubscribed && trialManager.remainingUses \== 0 && \!hasShownSubscriptionSplash {  
                                print("Showing subscription splash from RecipeCollectionView onBack")  
                                showSubscriptionSplash \= true  
                                hasShownSubscriptionSplash \= true  
                            }  
                        }  
                    })  
                    .transition(.opacity)  
                    .animation(.easeOut(duration: 0.69), value: showCollection)  
                } else if showSubscriptionSplash {  
                    PurchaseView(  
                        purchaseManager: purchaseManager,  
                        showSubscriptionSplash: \$showSubscriptionSplash  
                    )  
                    .environmentObject(viewModel)  
                    .background(Color.white)  
                    .transition(.opacity)  
                    .animation(.easeOut(duration: 0.69), value: showSubscriptionSplash)  
                    .zIndex(1)  
                    .onDisappear {  
                        print("PurchaseView disappeared, resetting hasShownSubscriptionSplash")  
                        hasShownSubscriptionSplash \= false  
                    }  
                } else {  
                    VStack(spacing: 20\) {  
                        Spacer()  
                        
                        VStack(spacing: 10\) {  
                            Image("RecipeSnap")  
                                .resizable()  
                                .scaledToFit()  
                                .frame(width: 236, height: 236\)  
                                .clipShape(RoundedRectangle(cornerRadius: 20))  
                                .scaleEffect(animateLogo ? 1 : 0.5)  
                                .opacity(animateLogo ? 1 : 0\)  
                            
                            Text("Recipe Snap")  
                                .font(.custom("SuperJellyfish", size: 36))  
                                .foregroundColor(.black)  
                                .scaleEffect(animateTitle ? 1 : 0.5)  
                                .opacity(animateTitle ? 1 : 0\)  
                            
                            RainbowTextView(text: "Snap ingredients to get a delicious recipe\!")  
                                .scaleEffect(animateTitle ? 1 : 0.5)  
                                .opacity(animateTitle ? 1 : 0\)  
                                .padding(.bottom, 30\)  
                            
                            Button(action: {  
                                triggerHaptic()  
                                if purchaseManager.isSubscribed \|\| trialManager.canGenerateRecipe() {  
                                    adViewModel.startProgressAnimation()  
                                    showCamera \= true  
                                } else {  
                                    print("Showing subscription splash from Snap Photo button")  
                                    showSubscriptionSplash \= true  
                                    hasShownSubscriptionSplash \= true  
                                }  
                            }) {  
                                Text("Snap Photo")  
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))  
                                    .padding(.vertical, 12\)  
                                    .padding(.horizontal, 24\)  
                                    .background(Color.black)  
                                    .foregroundColor(.white)  
                                    .clipShape(Capsule())  
                                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2\)  
                            }  
                            .fullScreenCover(isPresented: \$showCamera) {  
                                ZStack {  
                                    Color.black  
                                        .ignoresSafeArea(.all)  
                                    CameraPicker { imageData in  
                                        if let imageData \= imageData {  
                                            withAnimation {  
                                                adViewModel.startProgressAnimation()  
                                                showNativeAd \= true  
                                                viewModel.lastImageData \= imageData  
                                                viewModel.processPhoto(imageData) { result in  
                                                    DispatchQueue.main.async {  
                                                        showNativeAd \= false  
                                                        if result {  
                                                            showRecipe \= true  
                                                            if \!purchaseManager.isSubscribed {  
                                                                trialManager.useRecipe()  
                                                            }  
                                                        }  
                                                    }  
                                                }  
                                            }  
                                        }  
                                    }  
                                    .ignoresSafeArea(.all)  
                                }  
                                .background(Color.black)  
                                .animation(.easeInOut(duration: 0.3), value: showCamera)  
                            }  
                            .scaleEffect(animateButton ? 1 : 0.5)  
                            .opacity(animateButton ? 1 : 0\)  
                            
                            if purchaseManager.isSubscriptionStatusLoaded && \!purchaseManager.isSubscribed {  
                                Text("Recipes Remaining: \\(trialManager.remainingUses)")  
                                    .font(.system(size: 14, weight: .medium, design: .rounded))  
                                    .foregroundColor(.black.opacity(0.7))  
                                    .opacity(animateSubscriptionText ? 1 : 0\)  
                            }  
                            
                            if viewModel.isLoading && \!showNativeAd {  
                                ProgressView()  
                                    .progressViewStyle(.circular)  
                                    .tint(.black)  
                                    .scaleEffect(1.5)  
                            }  
                            
                            if let error \= viewModel.errorMessage {  
                                Text(error)  
                                    .font(.system(size: 14, weight: .medium))  
                                    .foregroundColor(.black.opacity(0.8))  
                                    .padding(.horizontal, 20\)  
                                    .padding(.top, 10\)  
                            }  
                        }  
                        .padding(20)  
                        .background(Color.white)  
                        .clipShape(RoundedRectangle(cornerRadius: 15))  
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5\)  
                        .padding(.horizontal, 16\)  
                        
                        Spacer()  
                    }  
                    .onAppear {  
                        withAnimation(.easeInOut(duration: 1.0)) {  
                            animateLogo \= true  
                        }  
                        withAnimation(.easeInOut(duration: 1.0).delay(0.3)) {  
                            animateBookmark \= true  
                        }  
                        withAnimation(.easeInOut(duration: 1.0).delay(0.6)) {  
                            animateTitle \= true  
                        }  
                        withAnimation(.easeInOut(duration: 1.0).delay(0.9)) {  
                            animateDescription \= true  
                        }  
                        withAnimation(.easeInOut(duration: 1.0).delay(1.2)) {  
                            animateButton \= true  
                        }  
                        if purchaseManager.isSubscriptionStatusLoaded {  
                            withAnimation(.easeInOut(duration: 1.0).delay(1.5)) {  
                                animateSubscriptionText \= true  
                            }  
                        }  
                        if purchaseManager.isSubscriptionStatusLoaded && \!purchaseManager.isSubscribed && trialManager.remainingUses \== 0 && \!hasShownSubscriptionSplash {  
                            print("Showing subscription splash from onAppear")  
                            showSubscriptionSplash \= true  
                            hasShownSubscriptionSplash \= true  
                        }  
                    }  
                    .onChange(of: purchaseManager.isSubscriptionStatusLoaded) { \_, isLoaded in  
                        if isLoaded {  
                            withAnimation(.easeInOut(duration: 1.0).delay(1.5)) {  
                                animateSubscriptionText \= true  
                            }  
                            if \!purchaseManager.isSubscribed && trialManager.remainingUses \== 0 && \!hasShownSubscriptionSplash {  
                                print("Showing subscription splash from onChange")  
                                showSubscriptionSplash \= true  
                                hasShownSubscriptionSplash \= true  
                            }  
                        }  
                    }  
                }  
                
                if \!showCollection && \!showSubscriptionSplash && \!showRecipe {  
                    VStack {  
                        HStack {  
                            Button(action: {  
                                triggerHaptic()  
                                showCollection \= true  
                            }) {  
                                Image(systemName: "bookmark")  
                                    .foregroundColor(.black)  
                                    .font(.system(size: 20))  
                                    .frame(height: 165\)  
                            }  
                            .padding(.leading, 20\)  
                            .scaleEffect(animateBookmark ? 1 : 0.5)  
                            .opacity(animateBookmark ? 1 : 0\)  
                            
                            Spacer()  
                            
                            Button(action: {  
                                triggerHaptic()  
                                print("Showing subscription splash from cart button")  
                                showSubscriptionSplash \= true  
                                hasShownSubscriptionSplash \= true  
                            }) {  
                                Image(systemName: "cart")  
                                    .foregroundColor(.black)  
                                    .font(.system(size: 20))  
                                    .frame(height: 165\)  
                            }  
                            .padding(.trailing, 20\)  
                            .scaleEffect(animateBookmark ? 1 : 0.5)  
                            .opacity(animateBookmark ? 1 : 0\)  
                        }  
                        .padding(.top, 20\)  
                        .ignoresSafeArea(.all, edges: .top)  
                        Spacer()  
                    }  
                }  
                
                if showNativeAd {  
                    NativeAdView(  
                        isRecipeReady: Binding(  
                            get: { viewModel.recipe \!= nil && \!viewModel.isLoading },  
                            set: { \_ in }  
                        ),  
                        isSubscribed: true  
                    )  
                    .environmentObject(adViewModel)  
                    .transition(.opacity)  
                }  
            }  
        }  
        .animation(.easeOut(duration: 0.69), value: showRecipe \|\| showCollection \|\| showNativeAd)  
        .environmentObject(BookmarkManager())  
    }  
    
    private func triggerHaptic() {  
        let impact \= UIImpactFeedbackGenerator(style: .medium)  
        impact.impactOccurred()  
    }  
}  
struct ContentView\_Previews: PreviewProvider {  
    static var previews: some View {  
        ContentView()  
    }  
}  
   
   
NativeAdView.swift:  
   
import SwiftUI  
struct HeaderHeightPreferenceKey: PreferenceKey {  
    static var defaultValue: CGFloat \= 0  
    static func reduce(value: inout CGFloat, nextValue: () \-\> CGFloat) {  
        value \= nextValue()  
    }  
}  
struct NativeAdView: View {  
    @Binding var isRecipeReady: Bool  
    let isSubscribed: Bool  
    @EnvironmentObject private var adViewModel: NativeAdViewModel  
    @State private var headerHeight: CGFloat \= 0  
    
    var body: some View {  
        GeometryReader { geometry in  
            let safeAreaTop \= geometry.safeAreaInsets.top  
            let safeAreaBottom \= geometry.safeAreaInsets.bottom  
            let topBuffer: CGFloat \= 40  
            let initialOffsetFactor: CGFloat \= 0.33  
            
            ZStack(alignment: .top) {  
                Color.white.ignoresSafeArea()  
                
                if isSubscribed {  
                    ZStack {  
                        Rectangle()  
                            .fill(  
                                LinearGradient(  
                                    gradient: Gradient(colors: \[.red, .orange, .yellow, .green, .blue, .purple, .red\]),  
                                    startPoint: .top,  
                                    endPoint: .bottom  
                                )  
                            )  
                            .frame(width: geometry.size.width, height: (geometry.size.height \+ safeAreaTop \+ safeAreaBottom \+ topBuffer) \* adViewModel.loadingProgress)  
                            .offset(y: (geometry.size.height \+ safeAreaBottom \- (geometry.size.height \* initialOffsetFactor)) \* (1 \- adViewModel.loadingProgress))  
                            .animation(.linear(duration: 17), value: adViewModel.loadingProgress)  
                            .ignoresSafeArea(.all, edges: .all)  
                        
                        Text("Your recipe is loading...")  
                            .font(.custom("SuperJellyfish", size: 36))  
                            .foregroundColor(.black)  
                            .multilineTextAlignment(.center)  
                            .padding(.horizontal, 20\)  
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2\)  
                    }  
                } else {  
                }  
            }  
            .onAppear {  
                adViewModel.startProgressAnimation()  
            }  
            .onChange(of: isRecipeReady) { oldValue, newValue in  
                if newValue {  
                    withAnimation {  
                        adViewModel.stopLoading()  
                    }  
                }  
            }  
        }  
    }  
}  
struct NativeAdView\_Previews: PreviewProvider {  
    static var previews: some View {  
        NativeAdView(isRecipeReady: .constant(false), isSubscribed: true)  
            .environmentObject(NativeAdViewModel())  
    }  
}  
   
   
NativeAdViewModel.swift:  
   
import Foundation  
import SwiftUI  
class NativeAdViewModel: NSObject, ObservableObject {  
    @Published var loadingProgress: CGFloat \= 0.0  
    @Published var isAdLoading: Bool \= false  
     
    private var progressTimer: Timer?  
     
    override init() {  
        super.init()  
    }  
     
    func startProgressAnimation() {  
        loadingProgress \= 0.0  
         
        stopProgressAnimation()  
         
        let duration: TimeInterval \= 17.0  
        let interval: TimeInterval \= 0.0167  
        let increment \= interval / duration  
         
        progressTimer \= Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { \[weak self\] timer in  
            guard let self \= self else {  
                timer.invalidate()  
                return  
            }  
             
            self.loadingProgress \+= increment  
            if self.loadingProgress \>= 1.0 {  
                self.loadingProgress \= 1.0  
                timer.invalidate()  
                self.progressTimer \= nil  
            }  
        }  
    }  
     
    func stopProgressAnimation() {  
        progressTimer?.invalidate()  
        progressTimer \= nil  
        loadingProgress \= 0.0  
    }  
     
    func stopLoading() {  
        stopProgressAnimation()  
    }  
}  
   
   
PurchaseManager.swift:  
   
import StoreKit  
import Foundation  
class PurchaseManager: ObservableObject, @unchecked Sendable {  
    @Published var isSubscribed: Bool \= false  
    @Published var products: \[Product\] \= \[\]  
    @Published var error: String?  
    @Published var isSubscriptionStatusLoaded: Bool \= false  
    private let productIDs \= \["10"\]  
     
    init() {  
        Task {  
            for await verificationResult in Transaction.updates {  
                if case .verified \= verificationResult {  
                    await checkSubscriptionStatus()  
                }  
            }  
        }  
         
        Task { @MainActor in  
            await fetchProducts()  
            await checkSubscriptionStatus()  
        }  
    }  
     
    func fetchProducts() async {  
        do {  
            let fetchedProducts \= try await Product.products(for: productIDs)  
            await MainActor.run {  
                print("Fetched Products: \\(fetchedProducts.map { "\\(\$0.id): \\(\$0.displayName) \- \\(\$0.displayPrice)" }.joined(separator: "; "))")  
                self.products \= fetchedProducts.sorted(by: { \$0.price \< \$1.price })  
                self.error \= nil  
            }  
        } catch {  
            await MainActor.run {  
                self.error \= "Failed to load products: \\(error.localizedDescription)"  
                print("Fetch Products Error: \\(error.localizedDescription)")  
            }  
        }  
    }  
     
    func purchase(product: Product) async {  
        print("Initiating purchase for product: \\(product.id) \- \\(product.displayName)")  
        do {  
            let result \= try await product.purchase()  
            print("Purchase result for \\(product.id): \\(result)")  
            switch result {  
            case .success(let verificationResult):  
                if case .verified \= verificationResult {  
                    print("Purchase successful and verified for \\(product.id)")  
                    await checkSubscriptionStatus()  
                } else {  
                    print("Purchase verification failed for \\(product.id)")  
                }  
            case .pending:  
                await MainActor.run {  
                    self.error \= "Purchase is pending approval."  
                    print("Purchase pending for \\(product.id)")  
                }  
            case .userCancelled:  
                print("Purchase cancelled by user for \\(product.id)")  
            @unknown default:  
                print("Unknown purchase result for \\(product.id)")  
            }  
        } catch {  
            await MainActor.run {  
                self.error \= "Purchase failed: \\(error.localizedDescription)"  
                print("Purchase error for \\(product.id): \\(error.localizedDescription)")  
            }  
        }  
    }  
     
    func restorePurchases() async {  
        var hasRestored \= false  
        for await verificationResult in Transaction.currentEntitlements {  
            if case .verified \= verificationResult {  
                hasRestored \= true  
                break  
            }  
        }  
        let finalHasRestored \= hasRestored  
         
        await MainActor.run {  
            if finalHasRestored {  
                Task {  
                    await self.checkSubscriptionStatus()  
                }  
            } else {  
                if \!self.isSubscribed {  
                    self.error \= "No active subscriptions found."  
                } else {  
                    self.error \= "No purchases to restore."  
                }  
            }  
        }  
    }  
     
    func refreshTransactions() async {  
        print("Forcing transaction refresh")  
        await checkSubscriptionStatus()  
    }  
     
    func checkSubscriptionStatus() async {  
        var isActive \= false  
        var transactionDetails: \[String\] \= \[\]  
         
        for await verificationResult in Transaction.currentEntitlements {  
            switch verificationResult {  
            case .verified(let transaction):  
                let productID \= transaction.productID  
                let transactionInfo \= "Product ID: \\(productID), Expiration: \\(transaction.expirationDate?.description ?? "None")"  
                transactionDetails.append(transactionInfo)  
                print("Verified Transaction: \\(transactionInfo)")  
                 
                if productID \== "10" {  
                    if let expirationDate \= transaction.expirationDate {  
                        let now \= Date()  
                        if now \< expirationDate {  
                            print("Subscription active: expires \\(expirationDate)")  
                            isActive \= true  
                            break  
                        } else {  
                            print("Subscription expired: expired on \\(expirationDate)")  
                        }  
                    } else {  
                        print("No expiration date (likely sandbox); assuming active")  
                        isActive \= true  
                        break  
                    }  
                }  
            case .unverified(let transaction, let error):  
                print("Unverified Transaction: Product ID: \\(transaction.productID), Error: \\(error)")  
                transactionDetails.append("Unverified: Product ID: \\(transaction.productID), Error: \\(error)")  
            }  
        }  
         
        let finalIsActive \= isActive  
        let finalTransactionDetails \= transactionDetails  
         
        await MainActor.run {  
            print("Subscription Status Check Complete: isSubscribed \= \\(finalIsActive)")  
            print("Transactions Found: \\(finalTransactionDetails.joined(separator: "; "))")  
            self.isSubscribed \= finalIsActive  
            self.isSubscriptionStatusLoaded \= true  
        }  
    }  
}  
   
   
PurchaseView.swift:  
   
import SwiftUI  
import StoreKit  
import UIKit  
struct PurchaseView: View {  
    @ObservedObject var purchaseManager: PurchaseManager  
    @Binding var showSubscriptionSplash: Bool  
    @State private var animateLogo \= false  
    @State private var animateTitle \= false  
     
    private let privacyPolicyURL \= URL(string: "https\://sites.google.com/view/recipesnap/home")\!  
    private let termsOfUseURL \= URL(string: "https\://www\.apple.com/legal/internet-services/itunes/dev/stdeula/")\!  
     
    var body: some View {  
        GeometryReader { geometry in  
            ZStack {  
                Color.white.edgesIgnoringSafeArea(.all)  
                 
                VStack(spacing: 20\) {  
                    Spacer()  
                     
                    Image("RecipeSnap")  
                        .resizable()  
                        .scaledToFit()  
                        .frame(width: 236, height: 236\)  
                        .clipShape(RoundedRectangle(cornerRadius: 20))  
                        .scaleEffect(animateLogo ? 1 : 0.5)  
                        .opacity(animateLogo ? 1 : 0\)  
                     
                    Text(purchaseManager.isSubscribed ? "Unlimited" : "Go Unlimited")  
                        .font(.custom("SuperJellyfish", size: 56))  
                        .foregroundColor(.black)  
                        .scaleEffect(animateTitle ? 1 : 0.5)  
                        .opacity(animateTitle ? 1 : 0\)  
                     
                    if \!purchaseManager.isSubscribed {  
                        Text("Free trial includes 5 recipe generations.")  
                            .font(.system(size: 16, weight: .medium, design: .rounded))  
                            .foregroundColor(.black.opacity(0.7))  
                            .multilineTextAlignment(.center)  
                            .padding(.horizontal, 20\)  
                            .scaleEffect(animateTitle ? 1 : 0.5)  
                            .opacity(animateTitle ? 1 : 0\)  
                         
                        Text("Unlock unlimited recipes and instant \\"New Recipe\\" generations for the same photo\!")  
                            .font(.system(size: 16, weight: .medium, design: .rounded))  
                            .foregroundColor(.black.opacity(0.7))  
                            .multilineTextAlignment(.center)  
                            .padding(.horizontal, 20\)  
                            .scaleEffect(animateTitle ? 1 : 0.5)  
                            .opacity(animateTitle ? 1 : 0\)  
                         
                        RainbowTextView(text: "Recipe Snap without limits ⤵️")  
                            .scaleEffect(animateTitle ? 1 : 0.5)  
                            .opacity(animateTitle ? 1 : 0\)  
                         
                        if purchaseManager.products.isEmpty {  
                            ProgressView()  
                                .progressViewStyle(.circular)  
                                .tint(.black)  
                                .scaleEffect(1.5)  
                        } else {  
                            ForEach(purchaseManager.products) { product in  
                                Button(action: {  
                                    print("Purchase button tapped for product: \\(product.id) \- \\(product.displayName)")  
                                    Task {  
                                        await purchaseManager.purchase(product: product)  
                                    }  
                                }) {  
                                    Text(product.displayName \+ " \- " \+ product.displayPrice)  
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))  
                                        .padding(.vertical, 12\)  
                                        .padding(.horizontal, 24\)  
                                        .background(Color.black)  
                                        .foregroundColor(.white)  
                                        .clipShape(Capsule())  
                                        .scaleEffect(animateTitle ? 1 : 0.5)  
                                        .opacity(animateTitle ? 1 : 0\)  
                                }  
                            }  
                        }  
                         
                        Button(action: {  
                            print("Restore Purchases button tapped")  
                            Task {  
                                await purchaseManager.restorePurchases()  
                            }  
                        }) {  
                            Text("Restore Purchases")  
                                .font(.system(size: 14, weight: .medium, design: .rounded))  
                                .foregroundColor(.black.opacity(0.7))  
                                .scaleEffect(animateTitle ? 1 : 0.5)  
                                .opacity(animateTitle ? 1 : 0\)  
                        }  
                        .padding(.vertical, 10\)  
                         
                        Text("Privacy Policy")  
                            .font(.system(size: 14, weight: .medium, design: .rounded))  
                            .foregroundColor(.blue)  
                            .onTapGesture {  
                                print("Privacy Policy tapped")  
                                UIApplication.shared.open(privacyPolicyURL)  
                            }  
                            .scaleEffect(animateTitle ? 1 : 0.5)  
                            .opacity(animateTitle ? 1 : 0\)  
                         
                        Text("Terms of Use")  
                            .font(.system(size: 14, weight: .medium, design: .rounded))  
                            .foregroundColor(.blue)  
                            .onTapGesture {  
                                print("Terms of Use tapped")  
                                UIApplication.shared.open(termsOfUseURL)  
                            }  
                            .scaleEffect(animateTitle ? 1 : 0.5)  
                            .opacity(animateTitle ? 1 : 0\)  
                         
                        if let error \= purchaseManager.error {  
                            Text(error)  
                                .font(.system(size: 14, weight: .medium))  
                                .foregroundColor(.red)  
                                .padding(.horizontal, 20\)  
                                .padding(.top, 10\)  
                        }  
                    } else {  
                        RainbowTextView(text: "You're subscribed to Recipe Snap Unlimited\!")  
                            .scaleEffect(animateTitle ? 1 : 0.5)  
                            .opacity(animateTitle ? 1 : 0\)  
                           
                        Text("Manage this subscription in settings.")  
                            .font(.system(size: 16, weight: .medium, design: .rounded))  
                            .foregroundColor(.black.opacity(0.7))  
                            .multilineTextAlignment(.center)  
                            .padding(.horizontal, 20\)  
                            .scaleEffect(animateTitle ? 1 : 0.5)  
                            .opacity(animateTitle ? 1 : 0\)  
                         
                        Text("Privacy Policy")  
                            .font(.system(size: 14, weight: .medium, design: .rounded))  
                            .foregroundColor(.blue)  
                            .onTapGesture {  
                                print("Privacy Policy tapped")  
                                UIApplication.shared.open(privacyPolicyURL)  
                            }  
                            .scaleEffect(animateTitle ? 1 : 0.5)  
                            .opacity(animateTitle ? 1 : 0\)  
                         
                        Text("Terms of Use")  
                            .font(.system(size: 14, weight: .medium, design: .rounded))  
                            .foregroundColor(.blue)  
                            .onTapGesture {  
                                print("Terms of Use tapped")  
                                UIApplication.shared.open(termsOfUseURL)  
                            }  
                            .scaleEffect(animateTitle ? 1 : 0.5)  
                            .opacity(animateTitle ? 1 : 0\)  
                    }  
                     
                    Spacer()  
                }  
                 
                VStack {  
                    HStack {  
                        Spacer()  
                        Button(action: {  
                            print("Close button tapped")  
                            triggerHaptic()  
                            withAnimation(.easeOut(duration: 0.69)) {  
                                showSubscriptionSplash \= false  
                            }  
                            print("After setting in PurchaseView, showSubscriptionSplash: \\(showSubscriptionSplash)")  
                        }) {  
                            Image(systemName: "xmark")  
                                .foregroundColor(.black)  
                                .font(.system(size: 20))  
                                .frame(width: 44, height: 44\)  
                                .background(Color.white.opacity(0.5))  
                                .clipShape(Circle())  
                        }  
                        .padding(.trailing, 7\)  
                        .padding(.top, 77\)  
                    }  
                    Spacer()  
                }  
                .ignoresSafeArea(.all, edges: .top)  
            }  
            .transition(.opacity)  
            .animation(.easeOut(duration: 1.0), value: showSubscriptionSplash)  
            .onAppear {  
                withAnimation(.easeInOut(duration: 1.0)) {  
                    animateLogo \= true  
                }  
                withAnimation(.easeInOut(duration: 1.0).delay(0.6)) {  
                    animateTitle \= true  
                }  
            }  
        }  
    }  
     
    private func triggerHaptic() {  
        let impact \= UIImpactFeedbackGenerator(style: .medium)  
        impact.impactOccurred()  
    }  
}  
struct RainbowTextView: View {  
    let text: String  
     
    var body: some View {  
        TimelineView(.animation) { context in  
            let time \= context.date.timeIntervalSince1970  
            let phase \= (time.truncatingRemainder(dividingBy: 2)) / 1  
             
            Text(text)  
                .font(.system(size: 16, weight: .medium, design: .rounded))  
                .foregroundStyle(  
                    LinearGradient(  
                        gradient: Gradient(colors: \[  
                            .red, .orange, .yellow, .green, .blue, .purple, .red  
                        \]),  
                        startPoint: UnitPoint(x: phase \- 1.0, y: 0),  
                        endPoint: UnitPoint(x: phase, y: \-1)  
                    )  
                )  
                .multilineTextAlignment(.center)  
                .padding(.horizontal, 20\)  
        }  
    }  
}  
struct PurchaseView\_Previews: PreviewProvider {  
    static var previews: some View {  
        let purchaseManager \= PurchaseManager()  
        purchaseManager.products \= \[\]  
        return PurchaseView(purchaseManager: purchaseManager, showSubscriptionSplash: .constant(true))  
    }  
}  
   
   
RecipeCardView.swift:  
   
import SwiftUI  
import UIKit  
struct RecipeCardView: View {  
    let recipe: Recipe  
    let isFromBookmarks: Bool  
    let onBack: () \-\> Void  
    let onNewRecipe: () \-\> Void  
    let isSubscribed: Bool  
    @State private var recipeImage: Image?  
    @State private var isBookmarked \= false  
    @EnvironmentObject private var bookmarkManager: BookmarkManager  
    var body: some View {  
        ScrollView {  
            VStack(spacing: 20\) {  
                imageSection  
                titleSection  
                contentSection  
                buttonSection  
            }  
            .padding(.vertical, 20\)  
        }  
        .background(Color.white)  
        .onAppear {  
            loadImage()  
            isBookmarked \= bookmarkManager.isBookmarked(recipe)  
        }  
    }  
    private var imageSection: some View {  
        Group {  
            if let recipeImage \= recipeImage {  
                recipeImage  
                    .resizable()  
                    .scaledToFill()  
                    .frame(width: 400\)  
                    .frame(height: 250\)  
                    .clipShape(RoundedRectangle(cornerRadius: 15))  
                    .clipped()  
            } else {  
                ProgressView()  
                    .progressViewStyle(.circular)  
                    .tint(.black)  
                    .scaleEffect(1.5)  
                    .frame(maxWidth: .infinity)  
                    .frame(height: 250\)  
            }  
        }  
        .overlay(  
            RoundedRectangle(cornerRadius: 15\)  
                .stroke(Color.black.opacity(0.2), lineWidth: 1\)  
        )  
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5\)  
    }  
    private var titleSection: some View {  
        VStack(spacing: 8\) {  
            Text(recipe.title)  
                .font(.custom("SuperJellyfish", size: 36))  
                .foregroundColor(.black)  
                .multilineTextAlignment(.center)  
                .padding(.horizontal)  
            Text(recipe.description)  
                .font(.system(size: 16, weight: .medium, design: .rounded))  
                .foregroundColor(.black.opacity(0.8))  
                .padding(.horizontal)  
        }  
    }  
    private var contentSection: some View {  
        VStack(spacing: 16\) {  
            VStack(alignment: .leading, spacing: 8\) {  
                Text("Ingredients")  
                    .font(.system(size: 20, weight: .semibold, design: .rounded))  
                    .foregroundColor(.black)  
                ForEach(recipe.ingredients.components(separatedBy: ", ").map { \$0.trimmingCharacters(in: .whitespaces) }, id: \\.self) { ingredient in  
                    Text("• \\(ingredient)")  
                        .font(.system(size: 16, weight: .regular, design: .rounded))  
                        .foregroundColor(.black.opacity(0.7))  
                        .padding(.vertical, 2\)  
                }  
            }  
            .frame(maxWidth: .infinity, alignment: .leading)  
            VStack(alignment: .leading, spacing: 8\) {  
                Text("Preparation")  
                    .font(.system(size: 20, weight: .semibold, design: .rounded))  
                    .foregroundColor(.black)  
                ForEach(Array(recipe.instructions.enumerated()), id: \\.offset) { index, step in  
                    Text("\\(index \+ 1).) \\(step)")  
                        .font(.system(size: 16, weight: .regular, design: .rounded))  
                        .foregroundColor(.black.opacity(0.7))  
                        .padding(.vertical, 2\)  
                }  
            }  
            .frame(maxWidth: .infinity, alignment: .leading)  
        }  
        .padding(20)  
        .background(Color.white)  
        .clipShape(RoundedRectangle(cornerRadius: 15))  
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5\)  
        .padding(.horizontal, 16\)  
    }  
    private var buttonSection: some View {  
        VStack(spacing: 10\) {  
            if \!isFromBookmarks {  
                Button(action: {  
                    triggerHaptic()  
                    isBookmarked.toggle()  
                    if isBookmarked {  
                        bookmarkManager.addRecipe(recipe)  
                    } else {  
                        bookmarkManager.removeRecipe(recipe)  
                    }  
                }) {  
                    Text(isBookmarked ? "Remove Bookmark" : "Bookmark Recipe")  
                        .font(.system(size: 18, weight: .semibold, design: .rounded))  
                        .padding(.vertical, 12\)  
                        .padding(.horizontal, 24\)  
                        .background(Color.black)  
                        .foregroundColor(.white)  
                        .clipShape(Capsule())  
                }  
            } else {  
                Button(action: {  
                    triggerHaptic()  
                    bookmarkManager.removeRecipe(recipe)  
                    onBack()  
                }) {  
                    Text("Remove Bookmark")  
                        .font(.system(size: 18, weight: .semibold, design: .rounded))  
                        .padding(.vertical, 12\)  
                        .padding(.horizontal, 24\)  
                        .background(Color.black)  
                        .foregroundColor(.white)  
                        .clipShape(Capsule())  
                }  
            }  
            if isSubscribed && \!isFromBookmarks {  
                Button(action: {  
                    triggerHaptic()  
                    onNewRecipe()  
                }) {  
                    Text("New Recipe")  
                        .font(.system(size: 18, weight: .semibold, design: .rounded))  
                        .padding(.vertical, 12\)  
                        .padding(.horizontal, 24\)  
                        .background(Color.black)  
                        .foregroundColor(.white)  
                        .clipShape(Capsule())  
                }  
                Button(action: {  
                    triggerHaptic()  
                    onBack()  
                }) {  
                    Text("Home")  
                        .font(.system(size: 18, weight: .semibold, design: .rounded))  
                        .padding(.vertical, 12\)  
                        .padding(.horizontal, 24\)  
                        .background(Color.black)  
                        .foregroundColor(.white)  
                        .clipShape(Capsule())  
                }  
            } else {  
                Button(action: {  
                    triggerHaptic()  
                    onBack()  
                }) {  
                    Text(isFromBookmarks ? "Back" : "New Recipe")  
                        .font(.system(size: 18, weight: .semibold, design: .rounded))  
                        .padding(.vertical, 12\)  
                        .padding(.horizontal, 24\)  
                        .background(Color.black)  
                        .foregroundColor(.white)  
                        .clipShape(Capsule())  
                }  
                .padding(.vertical, 10\)  
            }  
        }  
    }  
    private func triggerHaptic() {  
        let impact \= UIImpactFeedbackGenerator(style: .medium)  
        impact.impactOccurred()  
    }  
    private func loadImage() {  
        if let data \= Data(base64Encoded: recipe.imageBase64),  
           let uiImage \= UIImage(data: data) {  
            recipeImage \= Image(uiImage: uiImage)  
        } else {  
            recipeImage \= Image(systemName: "photo")  
        }  
    }  
}  
struct RecipeCardView\_Previews: PreviewProvider {  
    static var previews: some View {  
        RecipeCardView(  
            recipe: Recipe(  
                id: UUID(),  
                title: "Sample Recipe",  
                description: "A delicious dish\!",  
                ingredients: "Ingredient 1, Ingredient 2",  
                instructions: \["Step 1: Do this.", "Step 2: Do that."\],  
                imageBase64: "",  
                createdAt: Date()  
            ),  
            isFromBookmarks: false,  
            onBack: {},  
            onNewRecipe: {},  
            isSubscribed: false  
        )  
        .environmentObject(BookmarkManager())  
    }  
}  
   
   
RecipeCollectionView.swift:  
   
import SwiftUI  
struct RecipeCollectionView: View {  
    let onBack: () \-\> Void  
    @EnvironmentObject private var bookmarkManager: BookmarkManager  
    @EnvironmentObject private var purchaseManager: PurchaseManager  
    @StateObject private var viewModel \= RecipeViewModel()  
    @State private var selectedRecipe: Recipe?  
    
    var body: some View {  
        ZStack {  
            Color.white.edgesIgnoringSafeArea(.all)  
            
            if let selectedRecipe \= selectedRecipe {  
                RecipeCardView(  
                    recipe: selectedRecipe,  
                    isFromBookmarks: true,  
                    onBack: {  
                        withAnimation {  
                            triggerHaptic()  
                            self.selectedRecipe \= nil  
                        }  
                    },  
                    onNewRecipe: { },  
                    isSubscribed: purchaseManager.isSubscribed  
                )  
                .environmentObject(viewModel)  
                .transition(.opacity)  
            } else {  
                VStack(spacing: 20\) {  
                    HStack {  
                        Text("Recipe Collection")  
                            .font(.custom("SuperJellyfish", size: 36))  
                            .foregroundColor(.black)  
                        Spacer()  
                        Button(action: {  
                            withAnimation(.easeOut(duration: 0.69)) {  
                                triggerHaptic()  
                                onBack()  
                            }  
                        }) {  
                            Image(systemName: "xmark")  
                                .foregroundColor(.black)  
                                .font(.system(size: 20))  
                        }  
                    }  
                    .padding(.horizontal)  
                    
                    if bookmarkManager.bookmarkedRecipes.isEmpty {  
                        Text("No saved recipes yet.")  
                            .font(.system(size: 16, weight: .medium, design: .rounded))  
                            .foregroundColor(.black.opacity(0.7))  
                            .padding(.top, 20\)  
                    } else {  
                        List {  
                            ForEach(bookmarkManager.bookmarkedRecipes) { recipe in  
                                Button(action: {  
                                    triggerHaptic()  
                                    selectedRecipe \= recipe  
                                }) {  
                                    VStack(alignment: .leading, spacing: 8\) {  
                                        Text(recipe.title)  
                                            .font(.system(size: 20, weight: .semibold, design: .rounded))  
                                            .foregroundColor(.black)  
                                        Text(recipe.description)  
                                            .font(.system(size: 14, weight: .regular, design: .rounded))  
                                            .foregroundColor(.black.opacity(0.7))  
                                            .lineLimit(2)  
                                    }  
                                    .padding(.vertical, 4\)  
                                }  
                                .buttonStyle(PlainButtonStyle())  
                                .listRowBackground(Color.white)  
                                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))  
                            }  
                        }  
                        .listStyle(.plain)  
                    }  
                    
                    Spacer()  
                }  
                .padding(.top, 20\)  
            }  
        }  
        .animation(.easeOut(duration: 0.69), value: selectedRecipe \!= nil)  
    }  
    
    private func triggerHaptic() {  
        let impact \= UIImpactFeedbackGenerator(style: .medium)  
        impact.impactOccurred()  
    }  
}  
struct RecipeCollectionView\_Previews: PreviewProvider {  
    static var previews: some View {  
        RecipeCollectionView(onBack: {})  
            .environmentObject(BookmarkManager())  
            .environmentObject(PurchaseManager())  
    }  
}  
   
   
RecipeModels.swift:  
   
import Foundation  
struct Recipe: Identifiable, Codable, Equatable {  
    var id: UUID \= UUID()  
    let title: String  
    let description: String  
    let ingredients: String  
    let instructions: \[String\]  
    let imageBase64: String  
    let createdAt: Date?  
     
    enum CodingKeys: String, CodingKey {  
        case id, title, description, ingredients, instructions, imageBase64, createdAt  
    }  
     
    static func \== (lhs: Recipe, rhs: Recipe) \-\> Bool {  
        return lhs.id \== rhs.id &&  
               lhs.title \== rhs.title &&  
               lhs.description \== rhs.description &&  
               lhs.ingredients \== rhs.ingredients &&  
               lhs.instructions \== rhs.instructions &&  
               lhs.imageBase64 \== rhs.imageBase64 &&  
               lhs.createdAt \== rhs.createdAt  
    }  
}  
struct IngredientResponse: Decodable {  
    let ingredients: \[String\]  
     
    enum CodingKeys: String, CodingKey {  
        case choices, message, content, ingredients  
    }  
     
    init(from decoder: Decoder) throws {  
        let container \= try decoder.container(keyedBy: CodingKeys.self)  
         
        if let choices \= try? container.decode(\[MessageContainer\].self, forKey: .choices), let firstChoice \= choices.first {  
            if let content \= firstChoice.message.content {  
                self.ingredients \= content.ingredients  
            } else {  
                throw DecodingError.dataCorruptedError(  
                    forKey: IngredientResponse.CodingKeys.content,  
                    in: container,  
                    debugDescription: "Invalid content format in message"  
                )  
            }  
        } else if let ingredients \= try? container.decode(\[String\].self, forKey: .ingredients) {  
            self.ingredients \= ingredients  
        } else {  
            throw DecodingError.keyNotFound(  
                IngredientResponse.CodingKeys.ingredients,  
                .init(codingPath: container.codingPath, debugDescription: "No ingredients key found")  
            )  
        }  
    }  
}  
private struct MessageContainer: Decodable {  
    let message: Message  
     
    enum CodingKeys: String, CodingKey {  
        case message  
    }  
}  
private struct Message: Decodable {  
    let content: Content?  
     
    enum CodingKeys: String, CodingKey {  
        case content  
    }  
     
    init(from decoder: Decoder) throws {  
        let container \= try decoder.container(keyedBy: CodingKeys.self)  
        if let contentString \= try? container.decode(String.self, forKey: .content),  
           let contentData \= contentString.data(using: .utf8),  
           let parsedContent \= try? JSONDecoder().decode(Content.self, from: contentData) {  
            self.content \= parsedContent  
        } else if let content \= try? container.decode(Content.self, forKey: .content) {  
            self.content \= content  
        } else {  
            self.content \= nil  
        }  
    }  
}  
private struct Content: Decodable {  
    let ingredients: \[String\]  
     
    enum CodingKeys: String, CodingKey {  
        case ingredients  
    }  
}  
struct APIErrorResponse: Decodable {  
    let error: ErrorDetails  
     
    struct ErrorDetails: Decodable {  
        let message: String  
        let code: Int?  
    }  
}  
   
   
RecipeSnapApp.swift:  
   
import SwiftUI  
@main  
struct RecipeSnapApp: App {  
    @StateObject private var bookmarkManager \= BookmarkManager()  
    @StateObject private var purchaseManager \= PurchaseManager()  
    @Environment(\\.scenePhase) private var scenePhase  
    
    init() {  
    }  
    
    var body: some Scene {  
        WindowGroup {  
            ContentView()  
                .environmentObject(bookmarkManager)  
                .environmentObject(purchaseManager)  
                .background(Color.white.edgesIgnoringSafeArea(.all))  
                .onAppear {  
                    print("ContentView appeared")  
                }  
                .onChange(of: scenePhase) { oldPhase, newPhase in  
                    if newPhase \== .active {  
                    }  
                }  
        }  
    }  
}  
   
RecipeViewModel.swift:  
   
import SwiftUI  
class RecipeViewModel: ObservableObject {  
    @Published var recipe: Recipe?  
    @Published var errorMessage: String?  
    @Published var isLoading \= false  
    var lastImageData: Data?  
    private let apiService \= APIService()  
     
    func processPhoto(\_ imageData: Data, completion: @escaping (Bool) \-\> Void) {  
        DispatchQueue.main.async {  
            self.isLoading \= true  
            self.errorMessage \= nil  
            self.recipe \= nil  
        }  
         
        let base64String \= imageData.base64EncodedString().trimmingCharacters(in: .whitespacesAndNewlines)  
        guard \!base64String.isEmpty else {  
            DispatchQueue.main.async {  
                self.errorMessage \= "Failed to encode photo."  
                self.isLoading \= false  
                completion(false)  
            }  
            return  
        }  
         
        guard let encodedBase64 \= base64String.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {  
            DispatchQueue.main.async {  
                self.errorMessage \= "Failed to URL-encode photo."  
                self.isLoading \= false  
                completion(false)  
            }  
            return  
        }  
         
        apiService.identifyIngredients(base64Image: encodedBase64) { result in  
            switch result {  
            case .success(let ingredients):  
                self.apiService.generateRecipe(ingredients: ingredients) { result in  
                    DispatchQueue.main.async {  
                        self.isLoading \= false  
                        switch result {  
                        case .success(let recipe):  
                            self.recipe \= recipe  
                            self.errorMessage \= nil  
                            completion(true)  
                        case .failure(let error):  
                            let message: String  
                            if (error as NSError).code \== 401 {  
                                message \= "Authentication failed: Please check your API key."  
                            } else if (error as NSError).code \== 502 {  
                                message \= "Server error: Please try again later."  
                            } else {  
                                message \= "Failed to generate recipe: \\(error.localizedDescription)"  
                            }  
                            self.errorMessage \= message  
                            completion(false)  
                        }  
                    }  
                }  
            case .failure(let error):  
                DispatchQueue.main.async {  
                    self.isLoading \= false  
                    let message: String  
                    if (error as NSError).code \== 401 {  
                        message \= "Authentication failed: Please check your API key."  
                    } else if (error as NSError).code \== 502 {  
                        message \= "Server error: Please try again later."  
                    } else {  
                        message \= "Failed to identify ingredients: \\(error.localizedDescription)"  
                    }  
                    self.errorMessage \= message  
                    completion(false)  
                }  
            }  
        }  
    }  
}  
   
   
TrialManager.swift:  
   
import Foundation  
import UIKit  
class TrialManager: ObservableObject {  
    @Published var remainingUses: Int \= 5  
    private let totalLimit \= 5  
    private let usesKeyPrefix \= "RecipeSnapUses\_"  
    private var deviceIdentifier: String {  
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString // Fallback to UUID if no vendor ID  
    }  
    private var usesKey: String {  
        return usesKeyPrefix \+ deviceIdentifier  
    }  
     
    init() {  
        loadUsage()  
    }  
     
    func canGenerateRecipe() \-\> Bool {  
        return remainingUses \> 0  
    }  
     
    func useRecipe() {  
        if remainingUses \> 0 {  
            remainingUses \-= 1  
            saveUsage()  
        }  
    }  
     
    private func saveUsage() {  
        UserDefaults.standard.set(remainingUses, forKey: usesKey)  
    }  
     
    private func loadUsage() {  
        let storedUses \= UserDefaults.standard.integer(forKey: usesKey)  
        if storedUses \== 0 && UserDefaults.standard.object(forKey: usesKey) \== nil {  
            remainingUses \= totalLimit  
        } else {  
            remainingUses \= min(storedUses, totalLimit)  
        }  
        saveUsage()  
    }  
}