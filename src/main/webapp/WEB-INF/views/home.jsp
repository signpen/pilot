<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title><%= request.getAttribute("title") %></title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f5f7fb; color: #222; }
        .card { max-width: 720px; padding: 24px 28px; background: #fff; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.08); }
        h1 { margin-top: 0; }
        code { background: #eef3ff; padding: 2px 6px; border-radius: 6px; }
    </style>
</head>
<body>
<div class="card">
    <h1><%= request.getAttribute("title") %></h1>
    <p><%= request.getAttribute("message") %></p>
    <p>빌드 방식: <code>Ant</code></p>
    <p>프레임워크: <code>Spring MVC 4.3.30.RELEASE</code></p>
    <p>대상 JDK: <code>1.8</code></p>
    <p>런타임 Java 버전: <code><%= request.getAttribute("javaVersion") %></code></p>
</div>
</body>
</html>
