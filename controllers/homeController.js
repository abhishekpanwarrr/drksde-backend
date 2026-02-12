import homeService from "../services/homeService.js";

export const getHomeData = async (req, res, next) => {
    try {
        const data = await homeService.getHomeData();
        res.status(200).json({
            status: "success",
            data,
        });
    } catch (err) {
        next(err);
    }
};
